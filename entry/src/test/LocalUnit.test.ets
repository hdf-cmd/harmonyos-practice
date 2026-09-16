// 【知识点 3.2.8 hypium】模板自带的示例套件：演示生命周期钩子与基本断言。
// hypium 用法三件套：
//   describe('套件名', ...) —— 一组相关用例的容器
//   it('用例名', 0, 函数)   —— 一个最小可执行用例；中间的 0 是过滤参数（用例规模标记，默认 0）
//   expect(实际值).assertXxx(期望值) —— 断言，断言失败该用例记为 Failed
import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';

// 每个测试文件导出一个"套件启动函数"，供 List.test.ets 的 testsuite() 注册调用
export default function localUnitTest() {
  describe('localUnitTest', () => {
    // ===== 四个生命周期钩子（执行时机从上到下）=====
    beforeAll(() => {
      // 所有用例开始前执行一次：适合放"整套用例共用的昂贵准备"（如初始化数据库连接）
    });
    beforeEach(() => {
      // 每条用例开始前都执行：适合放"每条用例都要的干净环境"（如重置测试数据）
      // 执行次数 = it 的条数，保证用例之间互不干扰
    });
    afterEach(() => {
      // 每条用例结束后都执行：收尾清理（如删除临时数据）
    });
    afterAll(() => {
      // 所有用例结束后执行一次：整体清理
    });
    it('assertContain', 0, () => {
      // 一条用例：验证字符串断言
      let a = 'abc';
      let b = 'b';
      // 常用断言：assertContain 包含 / assertEqual 相等（还有 assertLargerThan、assertTrue 等）
      expect(a).assertContain(b);
      expect(a).assertEqual(a);
    });
  });
}
