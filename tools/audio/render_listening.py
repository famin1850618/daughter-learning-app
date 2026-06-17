#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
render_listening — V3.27 (2026-06-17)
英语听力题服务端预渲染：Edge-TTS(en-GB) 按角色合成 → ffmpeg 拼接成整题一个 mp3
→ 内容哈希命名 question_bank/audio/<hash>.mp3（CDN-only，不入 assets）→ 回写
每题 audio_hash + 把所选 voice 定住进 speakers[role].voice。

口音 en-GB（题库 Cambridge PET/FCE）；选音色按场景选角（casting.json，见
feedback-listening-voice-casting）。仅 5 个 en-GB 神经音：Sonia/Libby/Maisie(F)、
Ryan/Thomas(M)。

依赖：edge-tts + ffmpeg（imageio-ffmpeg 提供）。用 venv python 跑：
  /tmp/ttsenv/bin/python tools/audio/render_listening.py --casting /tmp/ttswork/casting.json --patch

不带 --patch = dry run（只合成+报告，不改 batch JSON / index）。
"""
import argparse
import asyncio
import glob
import hashlib
import json
import os
import re
import subprocess
import sys

ROOT = '/home/faminwsl/daughter_learning_app'
QB = os.path.join(ROOT, 'question_bank')
ASSETS = os.path.join(ROOT, 'assets/data/batches')
AUDIO_DIR = os.path.join(QB, 'audio')
BATCH_GLOB = os.path.join(QB, 'batch_*_english_pet_*.json')
ENGINE_VER = 'edge1'
RATE = '-10%'
SIL_MS = 350

VOICE_FULL = {
    'Sonia': 'en-GB-SoniaNeural', 'Libby': 'en-GB-LibbyNeural',
    'Maisie': 'en-GB-MaisieNeural', 'Ryan': 'en-GB-RyanNeural',
    'Thomas': 'en-GB-ThomasNeural',
}

import edge_tts  # noqa: E402
import imageio_ffmpeg  # noqa: E402
FFMPEG = imageio_ffmpeg.get_ffmpeg_exe()


def default_voice(profile):
    """无 casting 时按 {gender,age} 兜底取该类默认音色。"""
    g = (profile or {}).get('gender', 'female')
    a = (profile or {}).get('age', 'adult')
    if a in ('child', 'teen'):
        return 'Maisie' if g == 'female' else 'Thomas'
    return 'Sonia' if g == 'female' else 'Ryan'


def parse_turns(audio_text, speakers):
    """切 turns。按 speakers 的 key 前缀匹配（容忍角色名含空格）。
    无前缀行接上一 turn；纯独白 → 单 turn role '_'."""
    roles = sorted((speakers or {}).keys(), key=len, reverse=True)
    turns = []
    for raw in audio_text.split('\n'):
        line = raw.rstrip()
        if not line.strip():
            continue
        matched = None
        for r in roles:
            if r != '_' and line.startswith(r + ':'):
                matched = r
                text = line[len(r) + 1:].strip()
                break
        if matched is not None:
            turns.append([matched, text])
        elif turns:
            turns[-1][1] += ' ' + line.strip()
        else:
            turns.append(['_', line.strip()])
    return [(r, t) for r, t in turns if t]


def audio_hash(audio_text, role_voice):
    canon = audio_text + '|' + json.dumps(role_voice, sort_keys=True, ensure_ascii=False) \
        + f'|en-GB|{RATE}|{ENGINE_VER}'
    return hashlib.sha1(canon.encode('utf-8')).hexdigest()[:16]


async def synth_turn(text, voice_short, out_mp3):
    full = VOICE_FULL[voice_short]
    last = None
    for attempt in range(6):
        try:
            await edge_tts.Communicate(text, full, rate=RATE).save(out_mp3)
            if os.path.exists(out_mp3) and os.path.getsize(out_mp3) > 0:
                return
        except Exception as e:  # 503/ws handshake throttling etc.
            last = e
        await asyncio.sleep(2 ** attempt + 0.5)  # backoff 1.5,2.5,4.5,8.5,16.5,32.5
    raise RuntimeError(f'edge-tts failed after retries: {last}')


def make_silence(path):
    if os.path.exists(path):
        return
    subprocess.run([FFMPEG, '-y', '-f', 'lavfi', '-i',
                    'anullsrc=r=24000:cl=mono', '-t', str(SIL_MS / 1000),
                    '-acodec', 'libmp3lame', '-b:a', '48k', path],
                   check=True, capture_output=True)


def concat(parts, out_mp3):
    """用 concat filter 重编码拼接（鲁棒，不挑 codec 参数一致性）。"""
    cmd = [FFMPEG, '-y']
    for p in parts:
        cmd += ['-i', p]
    n = len(parts)
    filt = ''.join(f'[{i}:a]' for i in range(n)) + f'concat=n={n}:v=0:a=1[a]'
    cmd += ['-filter_complex', filt, '-map', '[a]',
            '-acodec', 'libmp3lame', '-b:a', '64k', out_mp3]
    subprocess.run(cmd, check=True, capture_output=True)


async def render_one(q, src, qi, casting, tmpdir):
    audio_text = q['audio_text']
    speakers = q.get('speakers') or {'_': {'gender': 'female', 'age': 'adult'}}
    cast = casting.get(f'{src}#{qi}', {})
    role_voice = {}
    for role, prof in speakers.items():
        v = cast.get(role) or default_voice(prof)
        if v not in VOICE_FULL:
            v = default_voice(prof)
        role_voice[role] = v
    h = audio_hash(audio_text, role_voice)
    out_mp3 = os.path.join(AUDIO_DIR, f'{h}.mp3')
    # 回写字段（幂等）
    q['audio_hash'] = h
    for role in speakers:
        speakers[role]['voice'] = role_voice[role]
    q['speakers'] = speakers
    if os.path.exists(out_mp3):
        return h, 'skip'
    # 合成各 turn
    turns = parse_turns(audio_text, speakers)
    sil = os.path.join(tmpdir, '_sil.mp3')
    make_silence(sil)
    parts = []
    for ti, (role, text) in enumerate(turns):
        v = role_voice.get(role) or default_voice(speakers.get(role))
        tp = os.path.join(tmpdir, f'{h}_{ti}.mp3')
        await synth_turn(text, v, tp)
        await asyncio.sleep(0.3)  # 节流，避免 edge 端 503
        if parts:
            parts.append(sil)
        parts.append(tp)
    if not parts:
        return h, 'empty'
    if len(parts) == 1:
        os.replace(parts[0], out_mp3)
    else:
        concat(parts, out_mp3)
    return h, 'rendered'


async def main_async(patch, casting_path):
    os.makedirs(AUDIO_DIR, exist_ok=True)
    tmpdir = '/tmp/ttswork/turns'
    os.makedirs(tmpdir, exist_ok=True)
    casting = {}
    if casting_path and os.path.exists(casting_path):
        casting = json.load(open(casting_path)).get('casting', {})
    files = sorted(glob.glob(BATCH_GLOB))
    stats = {'rendered': 0, 'skip': 0, 'empty': 0, 'questions': 0}
    patched = set()
    for fp in files:
        src = os.path.basename(fp)[:-5]
        d = json.load(open(fp))
        changed = False
        for qi, q in enumerate(d['questions']):
            if not q.get('audio_text'):
                continue
            stats['questions'] += 1
            h, status = await render_one(q, src, qi, casting, tmpdir)
            stats[status] = stats.get(status, 0) + 1
            changed = True
            print(f'  {src}#{qi} {status} -> {h}.mp3')
        if patch and changed:
            with open(fp, 'w') as f:
                json.dump(d, f, ensure_ascii=False, indent=2)
            ap = os.path.join(ASSETS, os.path.basename(fp))
            if os.path.exists(ap):
                with open(ap, 'w') as f:
                    json.dump(d, f, ensure_ascii=False, indent=2)
            patched.add(src)
    print('\n', stats)
    if not patch:
        print('Dry run: 加 --patch 写回 batch JSON + index')
        return
    # index batch_hash + version
    idx_path = os.path.join(QB, 'index.json')
    idx = json.load(open(idx_path))
    for b in idx['batches']:
        if b.get('source') in patched:
            actual = hashlib.sha1(open(os.path.join(QB, b['source'] + '.json'), 'rb').read()).hexdigest()
            b['batch_hash'] = actual
    idx['version'] = idx.get('version', 0) + 1
    with open(idx_path, 'w') as f:
        json.dump(idx, f, ensure_ascii=False, indent=2)
    print(f'index.json: {len(patched)} batch_hash synced, version -> {idx["version"]}')


if __name__ == '__main__':
    ap = argparse.ArgumentParser()
    ap.add_argument('--casting', default='/tmp/ttswork/casting.json')
    ap.add_argument('--patch', action='store_true')
    args = ap.parse_args()
    asyncio.run(main_async(args.patch, args.casting))
