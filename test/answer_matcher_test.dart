import 'package:flutter_test/flutter_test.dart';
import 'package:daughter_learning_app/models/question.dart';
import 'package:daughter_learning_app/utils/answer_matcher.dart';

void main() {
  bool fill(String user, String ans, {List<String>? blanks}) =>
      AnswerMatcher.isCorrect(
        userAns: user,
        correctAnswerField: ans,
        type: QuestionType.fillBlank,
        answerBlanks: blanks,
      );
  bool calc(String user, String ans) => AnswerMatcher.isCorrect(
        userAns: user,
        correctAnswerField: ans,
        type: QuestionType.calculation,
      );

  group('外围括号（坐标）双向等价', () {
    test('答案带全角括号，用户省括号 → 对', () {
      expect(fill('3,2', '（3，2）'), isTrue);
      expect(fill('3，2', '（3，2）'), isTrue);
      expect(fill('(3,2)', '（3，2）'), isTrue);
    });
    test('答案无括号，用户加括号 → 对', () {
      expect(fill('(3,2)', '3,2'), isTrue);
    });
    test('坐标值不同 → 错（安全）', () {
      expect(fill('3,3', '（3，2）'), isFalse);
    });
  });

  group('尾部单位可省（但写错单位仍错）', () {
    test('省单位 → 对', () {
      expect(fill('10', '10米'), isTrue);
      expect(fill('60', '60°'), isTrue);
      expect(fill('136', '136元'), isTrue);
    });
    test('带正确单位 → 对', () {
      expect(fill('10米', '10米'), isTrue);
    });
    test('写错单位 → 错（关键安全：5平方米≠5立方米）', () {
      expect(fill('5立方米', '5平方米'), isFalse);
      expect(fill('10千米', '10米'), isFalse);
    });
    test('数值不同 → 错', () {
      expect(fill('11', '10米'), isFalse);
    });
  });

  group('前置词剥离', () {
    test('x=5 接受 5', () {
      expect(fill('5', 'x=5'), isTrue);
      expect(fill('x=5', 'x=5'), isTrue);
    });
    test('答：12 接受 12', () {
      expect(fill('12', '答：12'), isTrue);
    });
    test('不同变量名 → 错', () {
      expect(fill('y=5', 'x=5'), isFalse);
    });
    test('"答案"不被误剥（无冒号）', () {
      expect(fill('答案', '答案'), isTrue);
      expect(fill('案', '答案'), isFalse);
    });
  });

  group('多空：分隔符 + 逐空 + 部分给分', () {
    final blanks = ['寄托', '制度', '籍'];
    test('逗号/顿号/分号/空格都能切', () {
      expect(fill('寄托,制度,籍', '', blanks: blanks), isTrue);
      expect(fill('寄托、制度、籍', '', blanks: blanks), isTrue);
      expect(fill('寄托;制度;籍', '', blanks: blanks), isTrue);
      expect(fill('寄托 制度 籍', '', blanks: blanks), isTrue);
    });
    test('空数对不上 → 整题错（但 perBlank 仍可逐空看）', () {
      expect(fill('寄托,制度', '', blanks: blanks), isFalse);
    });
    test('部分给分 partialScore', () {
      final r = AnswerMatcher.evaluatePartial(
        userAns: '寄托,制度,错', correctAnswerField: '',
        type: QuestionType.fillBlank, answerBlanks: blanks);
      expect(r.isCorrect, isFalse);
      expect(r.partialScore, closeTo(2 / 3, 1e-9));
    });
    test('perBlankResults 逐空对错', () {
      final res = AnswerMatcher.perBlankResults(
        userBlanks: ['寄托', '错', '籍'],
        answerBlanks: blanks, type: QuestionType.fillBlank);
      expect(res, [true, false, true]);
    });
  });

  group('多空 + 单位/括号宽松', () {
    test('每空各自宽松（单位可省、括号可略）', () {
      expect(fill('10,100', '', blanks: ['10米', '100平方米']), isTrue);
      expect(fill('3,2;6,4', '', blanks: ['（3，2）', '（6，4）']), isFalse,
          reason: '坐标含内部逗号在单框模式会切错——根治靠逐空输入框');
    });
    test('逐空 UI（‖ 分隔）：坐标含内部逗号也正确', () {
      final sep = AnswerMatcher.blankSep;
      expect(fill('3,2${sep}6,4', '', blanks: ['（3，2）', '（6，4）']), isTrue);
      // 空段对位：第二空空着 → 整题错、partial=0.5
      final r = AnswerMatcher.evaluatePartial(
        userAns: '3,2$sep', correctAnswerField: '',
        type: QuestionType.fillBlank, answerBlanks: ['（3，2）', '（6，4）']);
      expect(r.isCorrect, isFalse);
      expect(r.partialScore, closeTo(0.5, 1e-9));
    });
  });

  group('回归：原有数学等价不被破坏', () {
    test('π/隐式乘法/上标', () {
      expect(fill('pi*r*r*h/3', 'πr²h/3'), isTrue);
      expect(fill('PI R^2 H / 3', 'πr²h/3'), isTrue); // 去空格+小写归一
      // (1/3)x 与 x/3 非 normalize 等价，靠 ||| 别名：
      expect(fill('(1/3)*pi*r^2*h', 'πr²h/3|||(1/3)*pi*r^2*h'), isTrue);
    });
    test('||| 别名', () {
      expect(fill('0.5', '1/2|||0.5'), isTrue);
    });
    test('计算题列式取末值', () {
      expect(calc('1+2*3=7', '7'), isTrue);
      expect(calc('12', '12'), isTrue);
    });
    test('外围括号不误剥非包裹式', () {
      // (1+2)*3 整体不是被一对括号包住 → 不剥
      expect(fill('(1+2)*3', '(1+2)*3'), isTrue);
      expect(fill('9', '(1+2)*3'), isFalse);
    });
  });

  group('回归：选择/判断不受影响', () {
    test('选择题字母', () {
      expect(AnswerMatcher.isCorrect(
        userAns: 'A,C', correctAnswerField: 'AC',
        type: QuestionType.multipleChoice), isTrue);
    });
    test('判断题', () {
      expect(AnswerMatcher.isCorrect(
        userAns: '正确', correctAnswerField: '对',
        type: QuestionType.judgment), isTrue);
    });
  });
}
