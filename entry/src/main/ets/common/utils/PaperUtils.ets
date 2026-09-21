import { PaperInfo } from '../model/QuestionModel'

// 从试卷数组中随机抽取 n 张（Fisher-Yates 洗牌后取前 n 张）
// 约定：不修改原数组；n 大于等于总数时返回全部试卷的副本
export function getRandomPapers(papers: PaperInfo[], n: number): PaperInfo[] {
  const pool: PaperInfo[] = papers.slice()   // 副本，保护原数组
  for (let i = pool.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1))
    const tmp: PaperInfo = pool[i]
    pool[i] = pool[j]
    pool[j] = tmp
  }
  return n >= pool.length ? pool : pool.slice(0, n)
}

// 按 categoryName 过滤试卷：纯函数，不修改入参，返回新数组
// 用于考卷列表页"进哪个科目就只看哪科的卷"；无匹配科目时返回空数组
export function filterByCategory(papers: PaperInfo[], categoryName: string): PaperInfo[] {
  return papers.filter((paper: PaperInfo): boolean => paper.categoryName === categoryName)
}

// 科目聚合结果：categoryName 为科目名，count 为该科目下的试卷数量
export interface CategoryGroup {
  categoryName: string
  count: number
}

// 按 categoryName 对试卷做客户端聚合：纯函数，不修改入参
// 返回 [{ categoryName, count }]，类别顺序与其首次出现顺序一致
export function groupByCategory(papers: PaperInfo[]): CategoryGroup[] {
  const groups: CategoryGroup[] = []
  for (const paper of papers) {
    const found: CategoryGroup | undefined =
      groups.find((g: CategoryGroup): boolean => g.categoryName === paper.categoryName)
    if (found !== undefined) {
      // 命中已有分组：仅累加结果数组中自建对象的计数，不触碰入参
      found.count++
    } else {
      // 首次出现的类别：新建分组对象
      const group: CategoryGroup = { categoryName: paper.categoryName, count: 1 }
      groups.push(group)
    }
  }
  return groups
}
