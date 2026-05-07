#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Generate batch_2026_05_08_g7_english_r1 — Grade 7 English Round 1 (200 questions)"""
import json

questions = []
C,F = "choice","fill"
E,M,H = "easy","medium","hard"
R = 1

def c(ch,kp,cont,diff,ans,expl,opts,audio=None):
    q = {"chapter":ch,"knowledge_point":kp,"content":cont,"type":C,
         "difficulty":diff,"round":R,"options":opts,"answer":ans,"explanation":expl}
    if audio: q["audio_text"] = audio
    questions.append(q)

def f(ch,kp,cont,diff,ans,expl):
    questions.append({"chapter":ch,"knowledge_point":kp,"content":cont,"type":F,
                      "difficulty":diff,"round":R,"answer":ans,"explanation":expl})

# KP shortcuts
VXX="词汇/学校生活"; VHH="词汇/兴趣爱好"; VJJ="词汇/季节天气"; VCC="词汇/城市国家"; VJD="词汇/节日庆典"
GNS="语法时态/名词单复数"; GKS="语法时态/可数不可数名词"
GRC="语法时态/人称代词"; GZS="语法时态/物主代词"; GZS2="语法时态/指示代词"
GGW="语法时态/冠词用法"; GJS="语法时态/基数词序数词"; GJC="语法时态/介词常用搭配"
SHM="句型/How many/much"; SQS="句型/祈使句"; SCN="句型/can表能力"
DWT="日常交际/问路指路"; DGW="日常交际/购物对话"; DDH="日常交际/电话交流"; DYQ="日常交际/邀请与回应"
WZJ="写作/自我介绍"; WPY="写作/描写朋友"; WRH="写作/日常活动"
LDD="听力/听单词拼写"; LDH="听力/听对话答问题"; LJS="听力/听句子辨意"
LDW="听力/听短文判断正误"; LSZ="听力/听数字与时间"
ACX="阅读理解/细节理解题"; AZJ="阅读理解/主旨大意题"

# Chapter names
CH1="词汇扩展（初中核心词2000词）"
CH2="一般将来时与情态动词"
CH3="比较级与最高级"
CH4="there be 句型与介词"
CH5="阅读理解：记叙文"
CH6="写作：简单段落"

# Shared reading passages (reused across multiple questions)
P1 = ("Read the passage and answer:\n\n"
      "Tom is 13 years old. He goes to Green Middle School. His favorite subject is science. "
      "He has two best friends, Jack and Mary. They like playing basketball after school.\n\n")
P2 = ("Read the passage and answer:\n\n"
      "Lucy lives in Beijing with her family. She has one brother named Mike. "
      "Every morning, Lucy walks to school. It takes her 15 minutes. "
      "She loves drawing and reads books every evening.\n\n")
P3 = ("Read the passage and answer:\n\n"
      "Sam is from England. He is now studying in a Chinese school. "
      "He can speak a little Chinese. His teacher's name is Mr. Li. "
      "Sam thinks Chinese is interesting but difficult.\n\n")
P4 = ("Read the passage and answer:\n\n"
      "Today is Sunday. The weather is sunny and warm. "
      "Anna and her classmates go to the park. They play games and have a picnic. "
      "Anna says it is the best day of the week.\n\n")
P5 = ("Read the passage and answer:\n\n"
      "David gets up at 6:30 every morning. He has breakfast with his family. "
      "He goes to school by bus. After school, he does his homework first, then watches TV. "
      "He goes to bed at 9:30 pm.\n\n")
P6 = ("Read the passage and answer:\n\n"
      "The Spring Festival is the most important festival in China. "
      "Families get together and eat dumplings. Children get lucky money. "
      "People watch fireworks at night. It is a very happy time.\n\n")

# ══════════════════════════════════════════════
# CH1  词汇扩展  35q
# ══════════════════════════════════════════════
# Vocabulary — school life
c(CH1,VXX,"Which word means '图书馆' in English?",E,"B","library = 图书馆。laboratory = 实验室，gymnasium = 体育馆。",["A. laboratory","B. library","C. gymnasium","D. cafeteria"])
f(CH1,VXX,"The place where students eat lunch at school is the ___.",E,"cafeteria","cafeteria = 学生餐厅（食堂）。")
c(CH1,VXX,"What do you use to write on the blackboard?",E,"A","chalk（粉笔）用于在黑板上书写。",["A. chalk","B. pen","C. pencil","D. marker"])
f(CH1,VXX,"A person who teaches in a school is called a ___.",E,"teacher","teacher = 教师、老师。")
c(CH1,VXX,"Which of the following is a school subject?",E,"C","mathematics（数学）是学校科目；pencil是文具，desk是桌子，gym是体育馆。",["A. pencil","B. desk","C. mathematics","D. gym"])
# Vocabulary — hobbies
c(CH1,VHH,"Which word means '爱好' in English?",E,"B","hobby = 爱好。subject = 科目，hobby = 爱好。",["A. subject","B. hobby","C. history","D. music"])
f(CH1,VHH,"Playing the piano is an example of a ___.",E,"hobby","hobby（爱好）：弹钢琴是一种课余爱好。")
c(CH1,VHH,"Which word describes someone who likes painting?",M,"C","artistic（有艺术天赋的）描述喜欢绘画的人。",["A. athletic","B. musical","C. artistic","D. scientific"])
# Vocabulary — seasons & weather
c(CH1,VJJ,"Which season comes after spring?",E,"B","季节顺序：spring→summer→autumn→winter。春天之后是夏天。",["A. autumn","B. summer","C. winter","D. spring"])
f(CH1,VJJ,"When it rains, the weather is ___.",E,"rainy","下雨的天气描述为rainy（多雨的）。")
c(CH1,VJJ,"What is the Chinese meaning of 'foggy'?",M,"A","foggy = 有雾的。rainy = 多雨的，windy = 有风的，cloudy = 多云的。",["A. 有雾的","B. 多雨的","C. 有风的","D. 多云的"])
c(CH1,VJJ,"Which word means '暴风雪'?",M,"C","snowstorm / blizzard = 暴风雪。storm = 暴风雨，rain = 雨，frost = 霜。",["A. storm","B. rain","C. snowstorm","D. frost"])
# Vocabulary — cities & countries
c(CH1,VCC,"The capital of England is ___.",E,"B","英国的首都是伦敦（London）。",["A. Paris","B. London","C. Berlin","D. Rome"])
f(CH1,VCC,"People from Japan are called ___.",M,"Japanese","来自日本的人称为Japanese（日本人）。")
c(CH1,VCC,"Which country is in Asia?",M,"C","China（中国）在亚洲；France在欧洲，Brazil在南美洲，Australia在大洋洲。",["A. France","B. Brazil","C. China","D. Australia"])
# Vocabulary — festivals
c(CH1,VJD,"Christmas is celebrated on ___.",E,"C","圣诞节是12月25日，Western holiday。",["A. October 31","B. January 1","C. December 25","D. November 1"])
f(CH1,VJD,"The festival where people eat mooncakes is called the ___ Festival.",M,"Mid-Autumn","中秋节（Mid-Autumn Festival）：吃月饼，赏月。")
c(CH1,VJD,"Halloween is on ___.",M,"A","万圣节是10月31日，人们穿扮鬼怪服装。",["A. October 31","B. December 25","C. January 1","D. February 14"])
# Grammar — nouns
c(CH1,GNS,"The plural of 'child' is ___.",E,"B","child→children，不规则复数。",["A. childs","B. children","C. childes","D. childrens"])
f(CH1,GNS,"The plural of 'tooth' is ___.",E,"teeth","tooth→teeth，不规则复数。")
c(CH1,GNS,"Which noun is uncountable?",E,"C","water（水）是不可数名词，不能直接加复数。book、dog、apple可数。",["A. book","B. dog","C. water","D. apple"])
f(CH1,GNS,"The plural of 'leaf' is ___.",M,"leaves","leaf→leaves，以-f结尾的名词变复数去-f加-ves。")
c(CH1,GKS,"Which sentence is correct?",M,"B","不可数名词用some，不加-s；'some water'正确。",["A. I want two waters.","B. I want some water.","C. I want a water.","D. I want waters."])
# Grammar — pronouns
c(CH1,GRC,"Choose the correct pronoun: '___ is my best friend.' (talking about Mary)",E,"A","Mary是女性第三人称，单数主格用She。",["A. She","B. Her","C. He","D. They"])
f(CH1,GRC,"They → object form: ___",E,"them","they的宾格是them（\"我爱他们\"）。")
c(CH1,GZS,"Choose the correct possessive: 'This is ___ book.' (the book belongs to Tom)",E,"B","属于Tom的，用his（男性物主代词）。",["A. him","B. his","C. he","D. himself"])
f(CH1,GZS,"My → possessive pronoun form: ___",E,"mine","my（形容词性物主代词）→ mine（名词性物主代词）。")
c(CH1,GZS2,"'___ is my pen.' (pointing to a pen far away)",M,"B","指远处的物体用that（那个）。",["A. This","B. That","C. These","D. Those"])
# Grammar — articles
c(CH1,GGW,"Choose the correct article: 'She is ___ honest girl.'",M,"B","honest发元音音素/ɒ/，前用an。",["A. a","B. an","C. the","D. /（不填）"])
f(CH1,GGW,"We use ___ before a vowel sound.",E,"an","元音音素前用an（an apple, an hour）。")
c(CH1,GGW,"Which sentence uses the article correctly?",M,"C","the sun特指太阳，用定冠词the，正确。",["A. I see a sun.","B. She is the teacher.（第一次提及错误）","C. The sun is hot.","D. He is an student."])
# Numbers & ordinals
c(CH1,GJS,"What is the ordinal form of 'three'?",E,"A","three的序数词是third（第三）。",["A. third","B. three","C. thirth","D. threeth"])
f(CH1,GJS,"twenty + one = ___ (in words)",E,"twenty-one","21用英文写作twenty-one（用连字符）。")
# Listening
c(CH1,LDD,"Listen and choose the word you hear.",E,"A","录音内容是school（学校）。",["A. school","B. cool","C. fool","D. pool"],"school")
c(CH1,LDD,"Listen and choose the correct word.",M,"C","录音内容是library（图书馆）。",["A. factory","B. history","C. library","D. mystery"],"library")
c(CH1,LSZ,"Listen and choose the number you hear.",E,"B","录音是fifteen（15）。",["A. 50","B. 15","C. 5","D. 150"],"fifteen")

# ══════════════════════════════════════════════
# CH2  一般将来时与情态动词  35q
# ══════════════════════════════════════════════
# Will future
c(CH2,GRC,"Which sentence is in the future tense?",E,"C","'will go'是一般将来时；其他是现在时或过去时。",["A. She goes to school.","B. He went home.","C. They will visit the museum.","D. We are eating."])
f(CH2,GRC,"I will ___ (go) to Beijing next week.",E,"go","will后跟动词原形，所以用go。")
c(CH2,GRC,"'Will you come to my party?' — Negative answer:",E,"B","否定回答：No, I won't.（will not的缩写）",["A. No, I willn't.","B. No, I won't.","C. No, I don't.","D. No, I can't."])
f(CH2,GRC,"Tomorrow she ___ (visit) her grandparents.",M,"will visit","一般将来时：主语+will+动词原形。")
c(CH2,GRC,"Choose the correct form: 'He ___ be late for school.'",M,"A","will be：将来时be动词形式。",["A. will be","B. will is","C. is going be","D. be will"])
c(CH2,GRC,"'I am going to study tonight.' This means:",M,"B","be going to表示有计划的将来行动，与will含义相近。",["A. I studied last night.","B. I plan to study tonight.","C. I study every night.","D. I don't want to study."])
# Modal verbs — can
c(CH2,SCN,"'She can swim very well.' This means she ___ swim.",E,"A","can表示能力，她会游泳。",["A. is able to","B. must","C. may","D. should"])
f(CH2,SCN,"Can you play the guitar? — Yes, I ___.",E,"can","肯定回答：Yes, I can.（简短回答）")
c(CH2,SCN,"Which sentence uses 'can' correctly?",E,"A","'Can he speak French?'正确；其他用法有误。",["A. Can he speak French?","B. He can speaks French.","C. He cans speak French.","D. Can speaks French?"])
c(CH2,SCN,"'I can't find my keys.' What does this mean?",M,"B","can't = cannot，表示不能找到。",["A. I don't want to find my keys.","B. I am unable to find my keys.","C. I found my keys.","D. I shouldn't find my keys."])
# Modal verbs — must/should/may
c(CH2,GRC,"Which word means '应该' (advice)?",E,"C","should表示建议/应该；must表示必须；can表示能力；will表示将来。",["A. will","B. can","C. should","D. must"])
c(CH2,GRC,"'You must do your homework.' 'Must' here means:",M,"A","must表示必须（义务/命令）。",["A. It is necessary/required.","B. You are able to.","C. You are planning to.","D. You choose to."])
f(CH2,GRC,"You ___ not run in the classroom. (prohibition)",M,"must","must not（mustn't）表示禁止，不能……")
c(CH2,GRC,"'May I open the window?' This is asking for:",M,"B","May I…?是请求许可的礼貌表达。",["A. information","B. permission","C. advice","D. ability"])
# Ordinal numbers & dates
c(CH2,GJS,"What is the date format in English? 'The third of May, 2026'",M,"B","英语日期：the 3rd of May / May 3rd。",["A. May Three, 2026","B. May 3rd, 2026","C. 3 May rd, 2026","D. May the Three"])
f(CH2,GJS,"Write the ordinal: 2nd = ___",E,"second","第二 = second。1st=first, 2nd=second, 3rd=third, 4th=fourth。")
# Prepositions
c(CH2,GJC,"'The book is ___ the table.' (on top of the table)",E,"A","on表示在……上面（接触表面）。",["A. on","B. in","C. under","D. behind"])
f(CH2,GJC,"He goes to school ___ bike. (by means of)",E,"by","by+交通工具（不用冠词）：by bike, by bus, by car。")
c(CH2,GJC,"'She lives ___ 12 Green Street.'",E,"B","地址前用at（具体地址）。",["A. in","B. at","C. on","D. by"])
c(CH2,GJC,"'The meeting is ___ Monday morning.'",M,"A","时间前：at+具体时刻，on+星期/日期，in+月份/年份。星期几用on。",["A. on","B. at","C. in","D. by"])
# Conversations — invitations
c(CH2,DYQ,"'Would you like to come to my birthday party?' — Polite acceptance:",E,"A","接受邀请：\"Yes, I'd love to.\"是礼貌接受邀请的表达。",["A. Yes, I'd love to.","B. No, I wouldn't.","C. I don't know you.","D. Maybe never."])
c(CH2,DYQ,"'Can you come to my house this Saturday?' — Declining politely:",M,"B","礼貌拒绝：\"I'm sorry, I can't. I have other plans.\"先道歉再解释。",["A. No, I hate you.","B. I'm sorry, I can't. I have other plans.","C. Yes, I'd love to.","D. What time?"])
f(CH2,DYQ,"'Let's go to the cinema tonight!' — Agreeing: '___ a good idea!'",E,"What","\"What a good idea!\"是同意并赞扬提议的常用表达。")
# Phone conversations
c(CH2,DDH,"'Hello, may I speak to Tom?' This is a phrase used when:",E,"A","这是打电话时的开场白，请求接通某人。",["A. Making a phone call","B. Meeting someone in person","C. Writing a letter","D. Sending an email"])
c(CH2,DDH,"'This is Mary speaking.' In a phone call, this means:",E,"B","This is [name] speaking.是电话中的自我介绍。",["A. Mary is not available.","B. The speaker's name is Mary.","C. Mary is leaving.","D. Mary doesn't want to talk."])
# Listening
c(CH2,LDH,"Listen to the dialogue and answer: Where is Tom going?",M,"B","录音：Tom: I will go to the library after school. 所以Tom要去图书馆。",["A. The gym","B. The library","C. The park","D. The shop"],"Tom: I will go to the library after school.")
c(CH2,LJS,"Listen and choose what the speaker means.",M,"C","录音：You should bring an umbrella today. 建议带伞，暗示今天会下雨。",["A. It is sunny today.","B. The speaker lost an umbrella.","C. It might rain today.","D. The speaker hates rain."],"You should bring an umbrella today.")
c(CH2,LSZ,"Listen and choose the correct time.",E,"A","录音：It is half past seven. 七点半。",["A. 7:30","B. 7:00","C. 8:30","D. 8:00"],"It is half past seven.")
# How many/much
c(CH2,SHM,"'___ apples are there on the table?'",E,"A","apples是可数名词，用How many（多少个）。",["A. How many","B. How much","C. How old","D. How far"])
f(CH2,SHM,"'___ milk do you need?' (milk is uncountable)",E,"How much","milk是不可数名词，问数量用How much。")
c(CH2,SHM,"'How much is this shirt?' This question is asking about:",E,"B","How much is…?询问价格。",["A. the colour","B. the price","C. the size","D. the brand"])
c(CH2,SQS,"Which sentence is an imperative (祈使句)?",E,"C","祈使句：无主语，动词原形开头，用于命令/请求/建议。",["A. She opens the door.","B. Will he open the door?","C. Open the door, please.","D. He will open the door."])
f(CH2,SQS,"An imperative sentence usually starts with a ___.",M,"verb","祈使句通常以动词原形开头（无主语）。")

# ══════════════════════════════════════════════
# CH3  比较级与最高级  30q
# ══════════════════════════════════════════════
c(CH3,GRC,"The comparative form of 'tall' is:",E,"A","tall→taller（一音节形容词加-er）。",["A. taller","B. more tall","C. tallest","D. most tall"])
f(CH3,GRC,"The comparative of 'big' is ___.",E,"bigger","big→bigger（以辅音结尾，双写辅音加-er）。")
c(CH3,GRC,"The superlative of 'beautiful' is:",E,"C","beautiful多音节，最高级：the most beautiful。",["A. beautifulest","B. beautifuller","C. the most beautiful","D. more beautiful"])
f(CH3,GRC,"The comparative of 'good' is ___.",E,"better","good→better→best（不规则比较级）。")
c(CH3,GRC,"'bad' → comparative → superlative:",M,"B","bad→worse→worst（不规则变化）。",["A. bad→badder→baddest","B. bad→worse→worst","C. bad→more bad→most bad","D. bad→worser→worsest"])
c(CH3,GRC,"'This book is ___ than that one.' (interesting)",M,"A","interesting多音节，比较级用more interesting。",["A. more interesting","B. interestinger","C. most interesting","D. interestinger than"])
f(CH3,GRC,"'far' → comparative: ___",M,"farther","far的比较级：farther（距离）或further（程度）。")
c(CH3,GRC,"'Tom is ___ student in the class.' (tall — superlative)",E,"B","最高级：the tallest（班级中最高的）。",["A. taller","B. the tallest","C. most tall","D. more tallest"])
c(CH3,GRC,"Which sentence uses the comparative correctly?",M,"C","比较级用than连接比较对象；用more+多音节形容词。",["A. She is more smarter than me.","B. He runs more faster.","C. This exam is more difficult than the last one.","D. This is the more interesting of the two books."])
c(CH3,GRC,"'as ___ as' structure means:",E,"A","as...as表示两者相同程度（一样…）。",["A. equally...","B. more than...","C. less than...","D. the most..."])
f(CH3,GRC,"'He is ___ tall ___ his brother.' (同样高)",M,"as...as","as tall as：和他哥哥一样高。")
# Shopping dialogue — comparison
c(CH3,DGW,"'I'd like to buy a pair of shoes. Do you have anything cheaper?'  The customer wants:",M,"B","顾客想要更便宜的（cheaper = 比较级）。",["A. More expensive shoes","B. Cheaper shoes","C. The cheapest shoes","D. The most expensive shoes"])
c(CH3,DGW,"'How much does this cost?' — 'It costs 50 yuan.' — 'That's too expensive. Do you have anything ___?'",M,"A","顾客觉得贵，想要cheaper（更便宜的）。",["A. cheaper","B. more expensive","C. better quality","D. bigger"])
f(CH3,DGW,"'This bag is 100 yuan. That bag is 80 yuan. That bag is ___ than this one.' (cheap)",E,"cheaper","80元比100元便宜，所以that bag is cheaper（更便宜）。")
c(CH3,DGW,"'Excuse me, how much is this jacket?' — Correct response:",E,"B","回答价格：It's [price].是标准回答方式。",["A. It is very nice.","B. It's 199 yuan.","C. What colour do you want?","D. My name is Li Ming."])
# Directions — comparisons of distance
c(CH3,DWT,"'Which way is shorter, the left or the right?' — 'The left is ___.'",M,"A","left路更短：shorter（比较级）。",["A. shorter","B. more shorter","C. the shortest","D. short"])
f(CH3,DWT,"'The school is ___ (far) from here than the park.' (远得多)",M,"farther","far的比较级farther，学校比公园更远。")
# Listening — comparisons
c(CH3,LDH,"Listen and choose: Who is taller?",M,"A","录音：Li Hua is taller than Wang Fang. 李华更高。",["A. Li Hua","B. Wang Fang","C. They are the same height.","D. Cannot tell."],"Li Hua is taller than Wang Fang.")
c(CH3,LJS,"Listen and choose what is being compared.",M,"B","录音：The blue bag is more expensive than the red one. 价格在比较。",["A. colour","B. price","C. size","D. weight"],"The blue bag is more expensive than the red one.")
# Reading — comparisons
c(CH3,ACX,"Read: 'Tom's bag weighs 5 kg. Jack's bag weighs 3 kg.' Whose bag is heavier?",E,"A","5 kg > 3 kg，所以Tom的包更重。",["A. Tom's","B. Jack's","C. Same weight","D. Cannot tell"])
f(CH3,ACX,"Read: 'May is 12. Her sister is 14.' May's sister is ___ than May.",E,"older","姐姐14岁，May 12岁，姐姐比May年长（older）。")
c(CH3,ACX,"Read: 'This summer was the hottest in 10 years.' This means:",M,"B","the hottest = 最高级，这个夏天是10年中最热的。",["A. This summer was warmer than last summer.","B. This summer was hotter than all the previous 10 summers.","C. This summer was cold.","D. This summer was normal."])
# Writing — description
c(CH3,WPY,"'My friend Lisa is ___ (tall) than me but ___ (short) than our teacher.' Fill in both blanks.",M,"A","比较级：taller（更高），shorter（更矮）。",["A. taller / shorter","B. tall / short","C. tallest / shortest","D. more tall / more short"])
c(CH3,WZJ,"When writing a self-introduction, which information should come first?",E,"A","自我介绍通常从姓名开始，然后是年龄、来自哪里等基本信息。",["A. Your name","B. Your favourite sport","C. Your future plans","D. Your pet's name"])
f(CH3,WZJ,"Complete: 'My name is Tom and I ___ (be) 13 years old.'",E,"am","I am 13 years old.（第一人称用am）")
c(CH3,WPY,"Which sentence best describes a friend's personality?",M,"C","描述性格特点用形容词：kind and helpful（善良且乐于助人）。",["A. He is 160 cm tall.","B. He has short hair.","C. He is kind and helpful.","D. He lives on Green Street."])
# Ordinals + dates
c(CH3,GJS,"What is the correct way to say '第五'?",E,"B","fifth（第五）是five的序数词，不规则变化。",["A. fiveth","B. fifth","C. fivth","D. five-th"])
f(CH3,GJS,"What is the ordinal number for 21? (in full words)",M,"twenty-first","21st = twenty-first（第二十一）。")
c(CH3,GJS,"'January is the ___ month of the year.'",E,"A","一月是一年中的第一个月，序数词first。",["A. first","B. one","C. second","D. once"])

# ══════════════════════════════════════════════
# CH4  there be 句型与介词  30q
# ══════════════════════════════════════════════
c(CH4,GJC,"'There ___ a book on the table.'",E,"A","there be 句型：be的形式取决于紧跟的名词。a book是单数，用is。",["A. is","B. are","C. be","D. have"])
f(CH4,GJC,"There ___ five students in the room.",E,"are","five students是复数，用are。")
c(CH4,GJC,"'There are some apples in the ___ (冰箱).'",E,"B","fridge（冰箱）是存放苹果的地方。",["A. book","B. fridge","C. school","D. park"])
c(CH4,GJC,"'Is there a post office near here?' — Correct reply:",M,"A","肯定回答：Yes, there is.（there be疑问句回答）",["A. Yes, there is.","B. Yes, it is.","C. Yes, there are.","D. Yes, there has."])
f(CH4,GJC,"'___ there any milk in the bottle?' (疑问句)",E,"Is","milk是不可数名词（单数），用Is。")
c(CH4,GJC,"'There aren't ___ chairs in the classroom.'",E,"A","否定句中用any（not any = no）。",["A. any","B. some","C. a","D. an"])
# Prepositions of place
c(CH4,GJC,"'The cat is ___ the box.' (猫在箱子里面)",E,"A","in表示在……内部。",["A. in","B. on","C. under","D. next to"])
f(CH4,GJC,"The lamp is ___ the table. (在桌子上方，悬挂着)",M,"above","above表示在……上方（不接触）；on表示接触表面。")
c(CH4,GJC,"'The school is ___ the bank and the hospital.'",M,"C","between表示在两者之间。",["A. in","B. behind","C. between","D. opposite"])
c(CH4,GJC,"'Go straight ahead and turn ___ at the traffic lights.' (左转)",M,"A","turn left = 左转。",["A. left","B. right","C. around","D. over"])
# Giving directions
c(CH4,DWT,"'Excuse me, is there a supermarket near here?' — 'Yes, ___ on Park Road.'",E,"B","it's = it is，指代前文提到的超市，在公园路上。",["A. there is","B. it's","C. there are","D. they're"])
c(CH4,DWT,"'How do I get to the train station?' — '___ go straight for two blocks, then turn right.'",E,"A","祈使句：Just go straight...（直走两个路口再右转）",["A. Just","B. Please can","C. You should might","D. Could are you"])
f(CH4,DWT,"'The museum is ___ from the school.' (opposite/对面)",M,"opposite","opposite表示在对面（across from）。")
c(CH4,DWT,"'Turn left at the traffic light, then the bank is ___ your right.'",M,"A","on the right / on your right：在右手边。",["A. on","B. at","C. in","D. by"])
# Prepositions of time
c(CH4,GJC,"'My birthday is ___ July.'",E,"B","月份前用in（in July）。",["A. on","B. in","C. at","D. by"])
c(CH4,GJC,"'The class starts ___ 8:00 am.'",E,"A","具体时刻前用at（at 8:00）。",["A. at","B. in","C. on","D. by"])
f(CH4,GJC,"'We have a holiday ___ Spring Festival.' (节日期间，用at)",E,"at","西方节日和某些节日用at：at Christmas, at Spring Festival。")
c(CH4,GJC,"'She was born ___ the morning.'",M,"A","一天中的时段：in the morning / afternoon / evening。",["A. in","B. on","C. at","D. during"])
# There be - extended
c(CH4,GJC,"Which sentence is correct?",M,"B","there be句型，be与最近的名词一致：a dog（单数）→there is。",["A. There is many students.","B. There is a dog in the garden.","C. There are a cat on the roof.","D. There have some books."])
c(CH4,GJC,"'There ___ a lot of furniture in the room.' (furniture is uncountable)",H,"A","furniture不可数，用is（单数形式）。",["A. is","B. are","C. were","D. have"])
# Directions — listening
c(CH4,LDH,"Listen: Where is the bank?",M,"A","录音：The bank is next to the post office. 银行在邮局旁边。",["A. Next to the post office","B. Opposite the school","C. Behind the hospital","D. On Green Road"],"The bank is next to the post office.")
c(CH4,LSZ,"Listen and choose the floor described.",M,"B","录音：The classroom is on the third floor. 三楼。",["A. Second floor","B. Third floor","C. First floor","D. Fourth floor"],"The classroom is on the third floor.")
# Writing — self-introduction (location)
c(CH4,WZJ,"'I live ___ Beijing, ___ the north of China.'",M,"A","住在某城市用in；北京在中国的北部用in the north of。",["A. in / in","B. at / on","C. on / at","D. in / on"])
f(CH4,WZJ,"'My school is ___ Park Street.' (具体地址)",E,"on","在某条街道上用on（on Park Street）。")
# Shopping
c(CH4,DGW,"'How much are these apples?' — '___ five yuan a kilogram.'",E,"A","They're = They are，回答价格。",["A. They're","B. It's","C. There are","D. Those are"])
c(CH4,DGW,"'I'll take two kilograms.' — 'That ___ ten yuan.'",M,"A","That comes to / That is ten yuan.（共计十元）",["A. comes to","B. come to","C. is coming to","D. came to"])
f(CH4,DGW,"'Can I help you?' — '___, I'm looking for a red jacket.'",E,"Yes","'Yes, I'm looking for...'是回应商店服务的标准开场。")
c(CH4,DWT,"'Excuse me, could you tell me the way to the library?' This is asking:",E,"A","这是问路的礼貌表达。",["A. For directions","B. For library membership","C. For a book","D. For the time"])
# Listening directions
c(CH4,LDH,"Listen: 'Go straight, then turn right.' Where does the speaker end up?",M,"C","根据录音指示：直走然后右转。具体目的地取决于上下文（这里是学校）。",["A. The park","B. The hospital","C. The school","D. The bank"],"Go straight for two blocks, then turn right. The school is on your left.")

# ══════════════════════════════════════════════
# CH5  阅读理解：记叙文  35q
# ══════════════════════════════════════════════
# Passage 1 — Tom
c(CH5,ACX,P1+"What is Tom's favorite subject?",E,"C","文中：'His favorite subject is science.'",["A. Math","B. English","C. Science","D. History"])
c(CH5,ACX,P1+"How many best friends does Tom have?",E,"B","文中：'He has two best friends, Jack and Mary.'",["A. One","B. Two","C. Three","D. Four"])
c(CH5,ACX,P1+"What do Tom and his friends do after school?",E,"B","文中：'They like playing basketball after school.'",["A. Swimming","B. Playing basketball","C. Reading books","D. Watching TV"])
c(CH5,ACX,P1+"How old is Tom?",E,"A","文中：'Tom is 13 years old.'",["A. 13","B. 12","C. 14","D. 15"])
f(CH5,AZJ,P1+"The passage is mainly about ___.",M,"Tom","短文主要介绍了Tom的基本信息：年龄、学校、爱好等。")
# Passage 2 — Lucy
c(CH5,ACX,P2+"Where does Lucy live?",E,"A","文中：'Lucy lives in Beijing with her family.'",["A. Beijing","B. Shanghai","C. London","D. New York"])
c(CH5,ACX,P2+"How does Lucy get to school?",E,"C","文中：'Every morning, Lucy walks to school.'",["A. By bus","B. By bike","C. On foot (walking)","D. By car"])
c(CH5,ACX,P2+"How long does it take Lucy to walk to school?",M,"B","文中：'It takes her 15 minutes.'",["A. 10 minutes","B. 15 minutes","C. 20 minutes","D. 30 minutes"])
c(CH5,ACX,P2+"What does Lucy love doing?",M,"A","文中：'She loves drawing and reads books every evening.'",["A. Drawing and reading","B. Swimming and singing","C. Cooking and running","D. Painting and dancing"])
f(CH5,AZJ,P2+"Lucy's brother's name is ___.",E,"Mike","文中：'She has one brother named Mike.'")
# Passage 3 — Sam
c(CH5,ACX,P3+"Where is Sam from?",E,"A","文中：'Sam is from England.'",["A. England","B. America","C. Australia","D. Canada"])
c(CH5,ACX,P3+"What does Sam think about Chinese?",M,"C","文中：'Sam thinks Chinese is interesting but difficult.'",["A. Easy and boring","B. Easy and interesting","C. Interesting but difficult","D. Boring and difficult"])
c(CH5,ACX,P3+"What is Sam's teacher's name?",E,"B","文中：'His teacher's name is Mr. Li.'",["A. Mr. Wang","B. Mr. Li","C. Mr. Chen","D. Mr. Zhang"])
f(CH5,ACX,P3+"Sam can speak a little ___.",E,"Chinese","文中：'He can speak a little Chinese.'")
c(CH5,AZJ,P3+"The best title for this passage is:",M,"C","文章主要介绍Sam（外国学生）在中国学校的生活。",["A. Chinese Schools","B. Learning English","C. A Foreign Student in China","D. My Teacher Mr. Li"])
# Passage 4 — Sunday
c(CH5,ACX,P4+"What is the weather like on Sunday?",E,"A","文中：'The weather is sunny and warm.'",["A. Sunny and warm","B. Rainy and cold","C. Cloudy and windy","D. Snowy and cold"])
c(CH5,ACX,P4+"Where do Anna and her classmates go?",E,"B","文中：'Anna and her classmates go to the park.'",["A. The cinema","B. The park","C. The library","D. The school"])
c(CH5,ACX,P4+"What do they do at the park?",M,"C","文中：'They play games and have a picnic.'",["A. Swimming and reading","B. Running and singing","C. Playing games and having a picnic","D. Drawing and dancing"])
f(CH5,ACX,P4+"Anna says Sunday is the ___ day of the week.",M,"best","文中：'Anna says it is the best day of the week.'")
# Passage 5 — David's daily routine
c(CH5,ACX,P5+"What time does David get up?",E,"A","文中：'David gets up at 6:30 every morning.'",["A. 6:30","B. 7:00","C. 6:00","D. 7:30"])
c(CH5,ACX,P5+"How does David go to school?",E,"B","文中：'He goes to school by bus.'",["A. By bike","B. By bus","C. On foot","D. By car"])
c(CH5,ACX,P5+"What does David do first after school?",M,"A","文中：'he does his homework first, then watches TV.'",["A. Does his homework","B. Watches TV","C. Eats dinner","D. Goes to bed"])
c(CH5,ACX,P5+"What time does David go to bed?",E,"C","文中：'He goes to bed at 9:30 pm.'",["A. 9:00 pm","B. 10:00 pm","C. 9:30 pm","D. 8:30 pm"])
f(CH5,AZJ,P5+"The passage describes David's ___.",M,"daily routine","文章描述了David每天的日常作息（daily routine）。")
# Passage 6 — Spring Festival
c(CH5,ACX,P6+"What is the most important festival in China?",E,"A","文中：'The Spring Festival is the most important festival in China.'",["A. Spring Festival","B. Mid-Autumn Festival","C. National Day","D. Dragon Boat Festival"])
c(CH5,ACX,P6+"What do families eat during the Spring Festival?",E,"B","文中：'Families get together and eat dumplings.'",["A. Mooncakes","B. Dumplings","C. Rice cakes","D. Noodles"])
c(CH5,ACX,P6+"What do children receive during the Spring Festival?",M,"C","文中：'Children get lucky money.'",["A. Flowers","B. Toys","C. Lucky money","D. Books"])
f(CH5,ACX,P6+"During the Spring Festival, people watch ___ at night.",E,"fireworks","文中：'People watch fireworks at night.'")
c(CH5,AZJ,P6+"The passage is mainly about:",E,"A","文章主要介绍春节的习俗和意义。",["A. The Spring Festival and its traditions","B. Chinese food","C. A family reunion","D. Chinese history"])
# General reading strategies
c(CH5,ACX,"When answering 'detail questions' in reading comprehension, you should:",M,"B","细节题：找到文中明确提到的具体信息，不要靠猜测或个人想象。",["A. Use your imagination","B. Find the specific information stated in the text","C. Write your own opinion","D. Count the words"])
c(CH5,AZJ,"A 'main idea' question asks you to find:",M,"A","主旨大意题：找出文章的核心主题或总体意思。",["A. The overall topic or message of the passage","B. A specific detail in one sentence","C. The author's name","D. The number of paragraphs"])

# ══════════════════════════════════════════════
# CH6  写作：简单段落  35q
# ══════════════════════════════════════════════
c(CH6,WZJ,"In a self-introduction, which sentence is the best opening?",E,"A","自我介绍以姓名开始是最自然的开场白。",["A. My name is Li Ming and I am 13 years old.","B. I like football very much.","C. My school has 1000 students.","D. Today is Monday."])
c(CH6,WZJ,"Which information is NOT typically in a short self-introduction?",M,"D","自我介绍通常包括姓名、年龄、爱好等，但不需要描述历史事件。",["A. Your name","B. Your hobbies","C. Where you are from","D. A historical event"])
f(CH6,WZJ,"'Hello! ___ is Tom. I am 14 years old.'",E,"My name","自我介绍：My name is Tom.（我的名字是汤姆。）")
c(CH6,WZJ,"Choose the best sentence to end a self-introduction.",M,"B","结尾可以表达期待或友好：'I hope we can be friends!'",["A. That's all.","B. I hope we can be friends!","C. Goodbye.","D. Thank you for reading."])
# Describing a friend
c(CH6,WPY,"Which sentence describes a friend's appearance?",E,"B","外貌描写：'She has long black hair and brown eyes.'描述外貌。",["A. She likes reading books.","B. She has long black hair and brown eyes.","C. She is very kind.","D. She studies hard every day."])
c(CH6,WPY,"Which sentence describes a friend's personality?",E,"C","性格描写：'She is very friendly and outgoing.'描述性格。",["A. She is 160 cm tall.","B. She has short hair.","C. She is very friendly and outgoing.","D. She lives near the school."])
f(CH6,WPY,"'My best friend ___ (name) is Wang Fang. She ___ (be) 13 years old.'",E,"is","第三人称单数用is（She is 13 years old）。")
c(CH6,WPY,"When describing a friend's hobbies, which form is correct?",M,"A","描述爱好：She likes + V-ing（动名词形式）。",["A. She likes playing tennis.","B. She like playing tennis.","C. She likes play tennis.","D. She is like playing tennis."])
# Daily activities — present tense
c(CH6,WRH,"Which sentence correctly describes a daily routine?",E,"A","一般现在时描述日常习惯：He gets up at 7:00 every morning.（每天早上7点起床）",["A. He gets up at 7:00 every morning.","B. He is getting up at 7:00 every morning.","C. He got up at 7:00 every morning.","D. He will gets up at 7:00 every morning."])
f(CH6,WRH,"'She ___ (have) breakfast at 7:30 every day.'",E,"has","第三人称单数一般现在时：has（have的第三人称单数形式）。")
c(CH6,WRH,"Which time word suggests a daily habit?",E,"C","every day（每天）表示习惯性动作，适合描述日常作息。",["A. yesterday","B. last week","C. every day","D. tomorrow"])
c(CH6,WRH,"'After school, I usually ___ my homework.' (do)",E,"A","usually+动词原形：do my homework（做作业）。",["A. do","B. does","C. did","D. doing"])
# Paragraph structure
c(CH6,WZJ,"A good paragraph should have:",M,"B","一个好的段落：有主题句（topic sentence），支撑细节（supporting details），结尾句（concluding sentence）。",["A. Only a topic sentence","B. A topic sentence, supporting details, and a conclusion","C. As many sentences as possible","D. No structure"])
c(CH6,WZJ,"A topic sentence should tell the reader:",M,"A","主题句：告诉读者这段文章的主要内容/中心思想。",["A. What the paragraph is mainly about","B. A random fact","C. The last idea","D. Personal feelings only"])
# Connectors
c(CH6,WRH,"'First, ___ Second, ___ Finally, ___' — These words help to:",E,"A","First/Second/Finally是时序连接词，帮助按顺序描述日常活动。",["A. Show the order of activities","B. Compare two things","C. Give reasons","D. Contrast ideas"])
f(CH6,WRH,"Use '___ ' to show contrast: 'I like maths, ___ I don't like history.'",M,"but","but（但是）表示转折对比关系。")
c(CH6,WPY,"'My friend is kind ___ hardworking.' (连接两个形容词)",E,"A","and连接两个并列形容词：kind and hardworking。",["A. and","B. but","C. or","D. so"])
# Error correction
c(CH6,WZJ,"Find the error: 'My name are Tom and I is 13 years old.'",E,"B","错误：are应该是is（My name is），is应该是am（I am）。",["A. My name","B. are / is (should be is / am)","C. Tom","D. 13"])
c(CH6,WRH,"Find the error: 'She go to school by bus every day.'",E,"B","第三人称单数一般现在时：go应改为goes。",["A. She","B. go (should be goes)","C. by bus","D. every day"])
c(CH6,WPY,"Find the error: 'He have two sisters and one brother.'",M,"A","第三人称单数：have应改为has。",["A. have (should be has)","B. sisters","C. and","D. brother"])
# Hobbies description
f(CH6,WPY,"'My friend loves ___ (play) basketball on weekends.'",E,"playing","love + V-ing（动名词）：loves playing basketball。")
c(CH6,WRH,"Which sentence is best for describing what you do every evening?",M,"C","'Every evening, I read for 30 minutes before bed.'是对日常活动的清晰描述。",["A. Yesterday evening was fun.","B. I will read books tomorrow.","C. Every evening, I read for 30 minutes before bed.","D. Reading is very good."])
# Listening for writing topics
c(CH6,LDH,"Listen: What does the speaker do on weekends?",M,"B","录音：I usually go swimming on weekends. 说话者周末去游泳。",["A. Play tennis","B. Go swimming","C. Read books","D. Watch movies"],"I usually go swimming on weekends.")
c(CH6,LJS,"Listen and choose the correct description of the speaker.",M,"A","录音：I am 13 years old and I like music and drawing. 说话者13岁，喜欢音乐和画画。",["A. 13 years old, likes music and drawing","B. 14 years old, likes sports","C. 12 years old, likes music","D. 13 years old, likes reading"],"I am 13 years old and I like music and drawing.")
# More vocabulary writing
c(CH6,WZJ,"Which word order is correct for a simple sentence?",E,"A","英语基本语序：主语+谓语+宾语（S+V+O）。",["A. Subject + Verb + Object","B. Verb + Subject + Object","C. Object + Subject + Verb","D. Verb + Object + Subject"])
c(CH6,WRH,"'I ___ (watch) TV for one hour every evening.'",E,"A","一般现在时：I watch（第一人称，动词原形）。",["A. watch","B. watches","C. watching","D. watched"])
f(CH6,WZJ,"'Nice to meet you! My ___ is Tom.'",E,"name","自我介绍：My name is Tom.（我叫汤姆，认识你很高兴！）")
c(CH6,WPY,"'She has ___ hair.' (describing short hair)",E,"B","描述外貌：short hair（短发）。",["A. long","B. short","C. tall","D. big"])
c(CH6,WZJ,"When writing about yourself, 'I' should be ___.",E,"C","英语中\"I\"始终大写，不管在句中哪个位置。",["A. lowercase (i)","B. only capitalized at the start","C. always capitalized","D. written as 'me'"])
c(CH6,WRH,"'My father works from Monday ___ Friday.'",E,"A","from…to…：从周一到周五，用to连接。",["A. to","B. at","C. on","D. in"])
c(CH6,WPY,"'My best friend is very ___.' Which word fits best to describe personality?",E,"B","generous（慷慨的）是描述性格/品质的形容词。",["A. tall","B. generous","C. blue","D. round"])
f(CH6,WZJ,"A paragraph that introduces yourself should include your name, age, and ___.",M,"hobbies","自我介绍段落通常包括：姓名、年龄和爱好（或其他基本信息）。")

# ══════════════════════════════════════════════
# Verify and write
# ══════════════════════════════════════════════
assert len(questions) == 200, f"Expected 200, got {len(questions)}"
types = {}; diffs = {}
for q in questions:
    types[q["type"]] = types.get(q["type"],0)+1
    diffs[q["difficulty"]] = diffs.get(q["difficulty"],0)+1
print(f"Total: {len(questions)}, Types: {types}, Difficulties: {diffs}")

data = {
    "source": "batch_2026_05_08_g7_english_r1",
    "subject": "english",
    "grade": 7,
    "knowledge_points_added": [],
    "questions": questions
}

for path in [
    "assets/data/batches/batch_2026_05_08_g7_english_r1.json",
    "question_bank/batch_2026_05_08_g7_english_r1.json"
]:
    with open(path, "w", encoding="utf-8") as fp:
        json.dump(data, fp, ensure_ascii=False, indent=2)
    print(f"Written: {path}")
