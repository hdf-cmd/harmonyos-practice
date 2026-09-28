import localUnitTest from './LocalUnit.test';
import paperFilterTest from './PaperUtils.test';

export default function testsuite() {
  localUnitTest();
  paperFilterTest();
}
