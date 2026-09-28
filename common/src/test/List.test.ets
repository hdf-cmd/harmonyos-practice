import localUnitTest from './LocalUnit.test';
import paperFilterTest from './PaperUtils.test';
import fontSettingTest from './FontSetting.test';

export default function testsuite() {
  localUnitTest();
  paperFilterTest();
  fontSettingTest();
}
