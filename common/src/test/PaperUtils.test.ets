// HAR 公共层纯函数单测：filterByCategory / groupByCategory。
//
// 【为什么用例设计要"独立算一遍"】断言的期望值不能用被测函数自己算（那叫同义反复，
//   函数怎么写都算对），这里一律用另一套实现（手写循环 / indexOf 去重）独立求值再比对。
// 【为什么不硬编码"8 套 / 3 科"】数据源是 MOCK_PAPERS，以后加删试卷会让硬编码计数假绿，
//   所以期望值随数据源推导，只在必要处加"数据源本身成立吗"的前置断言。
import { describe, it, expect } from '@ohos/hypium'
import { CategoryGroup, filterByCategory, groupByCategory } from '../main/ets/utils/PaperUtils'
import { PaperInfo } from '../main/ets/model/QuestionModel'
import { MOCK_PAPERS } from '../main/ets/mock/MockExamData'

// 独立实现：手写循环统计某科目的试卷数（供 filterByCategory 比对）
function tallyByCategory(papers: PaperInfo[], categoryName: string): number {
  let count: number = 0
  for (const paper of papers) {
    if (paper.categoryName === categoryName) {
      count++
    }
  }
  return count
}

// 独立实现：按首次出现顺序去重出科目名列表（既供组数比对，也供顺序比对）
function distinctCategories(papers: PaperInfo[]): string[] {
  const names: string[] = []
  for (const paper of papers) {
    if (names.indexOf(paper.categoryName) < 0) {
      names.push(paper.categoryName)
    }
  }
  return names
}

function makePaper(id: string, categoryName: string): PaperInfo {
  return {
    id: id, paperName: `测试卷${id}`, categoryName: categoryName, levelName: '测试',
    totalScore: 100, passScore: 60, duration: 30, questionCount: 6,
    maxAttempts: 3, attemptCount: 0, bestScore: 0
  }
}

export default function paperFilterTest() {
  describe('filterByCategoryTest', () => {
    it('should_only_contain_target_category_papers', 0, () => {
      const target: string = '鸿蒙认证'
      const result: PaperInfo[] = filterByCategory(MOCK_PAPERS, target)
      expect(MOCK_PAPERS.length > 0).assertTrue()
      expect(result.length > 0).assertTrue()
      expect(result.length).assertEqual(tallyByCategory(MOCK_PAPERS, target))
      for (const paper of result) {
        expect(paper.categoryName).assertEqual(target)
      }
    })
    it('should_return_empty_for_unknown_category', 0, () => {
      const result: PaperInfo[] = filterByCategory(MOCK_PAPERS, '不存在的科目')
      expect(result.length).assertEqual(0)
    })
    it('should_not_mutate_source_and_return_new_array', 0, () => {
      const source: PaperInfo[] = [makePaper('1', 'A'), makePaper('2', 'B'), makePaper('3', 'A')]
      const result: PaperInfo[] = filterByCategory(source, 'A')
      expect(source.length).assertEqual(3)
      expect(source[0].id).assertEqual('1')
      expect(source[1].categoryName).assertEqual('B')
      expect(result.length).assertEqual(2)
      const sameReference: boolean = result === source
      expect(sameReference).assertFalse()
    })
    it('should_return_empty_for_empty_input', 0, () => {
      const result: PaperInfo[] = filterByCategory([], '鸿蒙认证')
      expect(result.length).assertEqual(0)
    })
  })

  describe('groupByCategoryTest', () => {
    it('should_have_one_group_per_distinct_category', 0, () => {
      const expectedNames: string[] = distinctCategories(MOCK_PAPERS)
      expect(MOCK_PAPERS.length > 0).assertTrue()
      expect(expectedNames.length > 1).assertTrue()
      const groups: CategoryGroup[] = groupByCategory(MOCK_PAPERS)
      expect(groups.length).assertEqual(expectedNames.length)
    })
    it('should_count_match_independent_tally', 0, () => {
      const groups: CategoryGroup[] = groupByCategory(MOCK_PAPERS)
      let sum: number = 0
      for (const group of groups) {
        expect(group.count).assertEqual(tallyByCategory(MOCK_PAPERS, group.categoryName))
        sum += group.count
      }
      // 各组计数之和必须等于总数：漏归任何一份卷子都会被这条抓到
      expect(sum).assertEqual(MOCK_PAPERS.length)
    })
    it('should_keep_first_occurrence_order', 0, () => {
      const groups: CategoryGroup[] = groupByCategory(MOCK_PAPERS)
      const expectedNames: string[] = distinctCategories(MOCK_PAPERS)
      for (let i = 0; i < groups.length; i++) {
        expect(groups[i].categoryName).assertEqual(expectedNames[i])
      }
    })
    it('should_return_empty_for_empty_input', 0, () => {
      const groups: CategoryGroup[] = groupByCategory([])
      expect(groups.length).assertEqual(0)
    })
  })
}
