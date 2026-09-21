// 【知识点 3.2.8 hypium 单元测试】本文件是"测试套注册中心"。
//
// hypium 三件套：describe(测试套) / it(测试用例) / expect(断言)。
// 测试框架执行时只认一个入口——本文件导出的 testsuite() 函数，
// 所以每个测试文件写完后必须来这里"挂号"（import + 调用一次），
// 漏注册的测试文件不会被跑，等于没写——这是最容易踩的坑。
import localUnitTest from './LocalUnit.test';
import paperUtilsTest from './PaperUtils.test'
import timeUtilsTest from './TimeUtil.test';
import validationUtilTest from './ValidationUtil.test';
import loginViewModelTest from './LoginViewModel.test';
import homeViewModelTest from './HomeViewModel.test';

// 测试入口：函数名固定为 testsuite，由框架约定调用
export default function testsuite() {
  // 每个测试文件导出的"套件启动函数"在这里依次调用，相当于挂到执行清单上。
  // 新增测试文件的标准动作：① 新建 Xxx.test.ets 并导出函数 → ② 这里 import → ③ 这里调用。
  localUnitTest();
  paperUtilsTest();
  timeUtilsTest();
  validationUtilTest();
  loginViewModelTest();
  homeViewModelTest();
}
