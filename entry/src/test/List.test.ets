import localUnitTest from './LocalUnit.test';
import paperUtilsTest from './PaperUtils.test'

export default function testsuite() {
  localUnitTest();
  paperUtilsTest()
}