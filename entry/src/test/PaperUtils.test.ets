// 【知识点 3.2.8 hypium】getRandomPapers 的用例设计示例。
// 设计思路：一条函数的测试 = 正常路径 + 边界条件 + 不变式（约束）。
// 本套件四条用例正好四类：
//   ① 正常路径：抽 n 条就返回 n 条
//   ② 边界：n 超过总数 → 返回全部（不报错、不重复补齐）
//   ③ 不变式：结果不含重复（随机抽取不能抽重）
//   ④ 不变式：入参数组不被修改（纯函数约定，调用方的数据必须安全）
import { describe, it, expect } from '@ohos/hypium'
import { getRandomPapers } from '../main/ets/common/utils/PaperUtils'
import { PaperInfo } from '../main/ets/common/model/QuestionModel'

// 造 count 张最简测试试卷：测试里只需 id 有区分度，其余字段给合法值即可
// 把"造数据"抽成函数：每条用例都要用，避免重复代码（测试代码也要 DRY）
function makePapers(count: number): PaperInfo[] {
  const arr: PaperInfo[] = []
  for (let i = 1; i <= count; i++) {
    arr.push({
      id: `${i}`, paperName: `测试卷${i}`, categoryName: '测试', levelName: '测试',
      totalScore: 100, passScore: 60, duration: 30, questionCount: 6,
      maxAttempts: 3, attemptCount: 0, bestScore: 0
    })
  }
  return arr
}

export default function paperUtilsTest() {
  // 套件名建议"被测函数名 + Test"，一看便知测的是谁
  describe('getRandomPapersTest', () => {
    // 用例命名：should_xxx 描述预期行为，失败时看名字就知道哪条业务规则破了
    // 断言1（正常路径）：抽 3 条返回 3 条
    it('should_return_exact_n_papers', 0, () => {
      const result = getRandomPapers(makePapers(5), 3)
      expect(result.length).assertEqual(3)
    })
    // 断言2（边界）：n=10 超过总数 5，返回全部 5 条
    it('should_return_all_when_n_exceeds', 0, () => {
      const result = getRandomPapers(makePapers(5), 10)
      expect(result.length).assertEqual(5)
    })
    // 断言3（不变式）：抽 5 条不许有重复——用 Set 去重后数量应仍为 5
    it('should_have_no_duplicates', 0, () => {
      const result = getRandomPapers(makePapers(5), 5)
      const ids: string[] = result.map((p: PaperInfo) => p.id)
      expect(new Set<string>(ids).size).assertEqual(5)
    })
    // 断言4（不变式）：调用后原数组首元素不变、长度不变（函数内部必须用副本）
    it('should_not_mutate_source', 0, () => {
      const source = makePapers(5)
      getRandomPapers(source, 3)
      expect(source[0].id).assertEqual('1')
      expect(source.length).assertEqual(5)
    })
  })
}
