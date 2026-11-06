import hilog from '@ohos.hilog';
// assertContain 只是 hypium Assert 接口的方法，不是顶层导出成员，引进来编译不过，故只导三件。
import { describe, it, expect } from '@ohos/hypium';
import { CommonConstants } from '../main/ets/constants/CommonConstants';

export default function commonConstantsTest() {
  describe('CommonConstantsTest', () => {
    // 每个值都对着 restrained_native_precision/DESIGN.md 断言一次。
    // 这里不测"看起来对不对"，只测"有没有被人改动"——换装后 12 个屏都引用这些名字，
    // 改错一个数字不会编译失败，也不会让现有 121 例变红。
    it('primary_and_surface_colors', 0, () => {
      expect(CommonConstants.COLOR_PRIMARY).assertEqual('#0A59F7');
      expect(CommonConstants.COLOR_PRIMARY_PRESSED).assertEqual('#084ECC');
      expect(CommonConstants.COLOR_BG_PAGE).assertEqual('#F1F3F5');
      expect(CommonConstants.COLOR_CARD_BG).assertEqual('#FFFFFF');
      expect(CommonConstants.COLOR_SUBTLE_BG).assertEqual('#F2F4F6');
    });

    it('text_hierarchy_colors', 0, () => {
      expect(CommonConstants.COLOR_TEXT_MAIN).assertEqual('#182431');
      expect(CommonConstants.COLOR_TEXT_SUB).assertEqual('#525F70');
      expect(CommonConstants.COLOR_TEXT_HINT).assertEqual('#8A95A5');
      expect(CommonConstants.COLOR_TEXT_DISABLED).assertEqual('#BAC2CE');
    });

    it('semantic_colors_and_tints', 0, () => {
      expect(CommonConstants.COLOR_SUCCESS).assertEqual('#00B578');
      expect(CommonConstants.COLOR_ERROR).assertEqual('#E84026');
      expect(CommonConstants.COLOR_WARN).assertEqual('#FA6400');
      // 浅色底必须是 #AARRGGBB，alpha = round(0.08 × 255) = 20 = 0x14
      expect(CommonConstants.COLOR_SUCCESS_BG).assertEqual('#1400B578');
      expect(CommonConstants.COLOR_ERROR_BG).assertEqual('#14E84026');
      expect(CommonConstants.COLOR_WARN_BG).assertEqual('#14FA6400');
      expect(CommonConstants.COLOR_PRIMARY_BG).assertEqual('#140A59F7');
    });

    it('hairline_and_focus_borders', 0, () => {
      expect(CommonConstants.COLOR_BORDER_HAIRLINE).assertEqual('#0A000000');
      expect(CommonConstants.COLOR_BORDER_FOCUS).assertEqual('#660A59F7');
      expect(CommonConstants.COLOR_OVERLAY).assertEqual('#66182431');
    });

    it('font_scale_matches_design_md', 0, () => {
      expect(CommonConstants.FONT_DISPLAY_SCORE).assertEqual(48);
      expect(CommonConstants.FONT_DISPLAY_SCORE_MOBILE).assertEqual(36);
      expect(CommonConstants.FONT_HEADLINE_LG).assertEqual(28);
      expect(CommonConstants.FONT_HEADLINE_LG_MOBILE).assertEqual(22);
      expect(CommonConstants.FONT_HEADLINE_MD).assertEqual(20);
      expect(CommonConstants.FONT_HEADLINE_SM).assertEqual(16);
      expect(CommonConstants.FONT_BODY_LG).assertEqual(16);
      expect(CommonConstants.FONT_BODY_MD).assertEqual(14);
      expect(CommonConstants.FONT_BODY_SM).assertEqual(12);
      expect(CommonConstants.FONT_LABEL_MD).assertEqual(14);
      expect(CommonConstants.FONT_LABEL_SM).assertEqual(12);
      expect(CommonConstants.FONT_CAPTION_UNIT).assertEqual(11);
    });

    it('line_heights_pair_with_their_font_tier', 0, () => {
      // 字号与行高成对写死：只改字号不改行高，五档下会越挤越近
      expect(CommonConstants.LINE_DISPLAY_SCORE).assertEqual(56);
      expect(CommonConstants.LINE_DISPLAY_SCORE_MOBILE).assertEqual(44);
      expect(CommonConstants.LINE_HEADLINE_LG).assertEqual(36);
      expect(CommonConstants.LINE_HEADLINE_LG_MOBILE).assertEqual(30);
      expect(CommonConstants.LINE_HEADLINE_MD).assertEqual(28);
      expect(CommonConstants.LINE_HEADLINE_SM).assertEqual(24);
      expect(CommonConstants.LINE_BODY_LG).assertEqual(26);
      expect(CommonConstants.LINE_BODY_MD).assertEqual(22);
      expect(CommonConstants.LINE_BODY_SM).assertEqual(18);
      expect(CommonConstants.LINE_LABEL_MD).assertEqual(20);
      expect(CommonConstants.LINE_LABEL_SM).assertEqual(16);
      expect(CommonConstants.LINE_CAPTION_UNIT).assertEqual(14);
    });

    it('shape_and_space_scale', 0, () => {
      expect(CommonConstants.BTN_HEIGHT).assertEqual(48);
      expect(CommonConstants.BTN_HEIGHT_SECONDARY).assertEqual(36);
      expect(CommonConstants.RADIUS_CARD).assertEqual(16);
      expect(CommonConstants.RADIUS_BUTTON).assertEqual(8);
      expect(CommonConstants.RADIUS_INPUT).assertEqual(10);
      expect(CommonConstants.RADIUS_CHECKBOX).assertEqual(6);
      expect(CommonConstants.SPACE_M).assertEqual(16);
      expect(CommonConstants.SPACE_L).assertEqual(24);
      expect(CommonConstants.SPACE_CARD_GAP).assertEqual(12);
    });
  });
}
