/**
 * @file ScanTool.ets
 * @description 扫码工具组件。S22 新增:接入 ScanKit 系统扫码 UI。
 *
 * 鸿蒙文档依据:
 *   - @kit.ScanKit → scanBarcode.startScanForResult(context, options)
 *   - 无需手动申请 ohos.permission.CAMERA(系统自动处理)
 *   - 错误码 1000500002 = 用户取消(静默处理)
 *   - ScanResult.originalValue = 扫码内容, scanType = 码类型
 */

import { scanBarcode, scanCore } from "@kit.ScanKit";
import { hilog } from "@kit.PerformanceAnalysisKit";

const TAG: string = "ScanTool";
const DOMAIN: number = 0x0000;

@ComponentV2
export struct ScanTool {
  @Local scanResult: string = "";
  @Local resultCodeType: string = "";
  @Local hasResult: boolean = false;

  /** 扫码结果回调(父组件用于判断是否 URL 并跳转 WebContainer)。 */
  @Event onScanResult: (value: string) => void = (_value: string): void => {};

  build() {
    Column({ space: 16 }) {
      // 提示文字
      Text("将二维码/条形码放入框内，即可自动识别")
        .fontSize($r("app.float.fs_text_body"))
        .fontColor($r("app.color.fs_color_text_secondary"))
        .textAlign(TextAlign.Center)
        .padding({ left: 32, right: 32 })

      // 扫码按钮
      Button("开始扫码")
        .fontSize($r("app.float.fs_text_body"))
        .fontColor($r("app.color.fs_color_text_inverse"))
        .backgroundColor($r("app.color.fs_color_primary"))
        .borderRadius($r("app.float.fs_radius_md"))
        .height($r("app.float.fs_height_button"))
        .width(200)
        .onClick((): void => { this.startScan(); })

      // 结果展示区
      if (this.hasResult) {
        Column({ space: 8 }) {
          Text("扫码结果")
            .fontSize($r("app.float.fs_text_body_lg"))
            .fontWeight(FontWeight.Bold)
            .fontColor($r("app.color.fs_color_text_primary"))

          Text(this.resultCodeType)
            .fontSize($r("app.float.fs_text_caption"))
            .fontColor($r("app.color.fs_color_text_tertiary"))

          Text(this.scanResult)
            .fontSize($r("app.float.fs_text_body"))
            .fontColor($r("app.color.fs_color_primary"))
            .textAlign(TextAlign.Center)
            .maxLines(5)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .padding({ left: 16, right: 16 })
            .copyOption(CopyOptions.LocalDevice)
        }
        .padding(16)
        .borderRadius($r("app.float.fs_radius_md"))
        .backgroundColor($r("app.color.fs_color_surface"))
        .width("90%")
      }
    }
    .width("100%")
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  private startScan(): void {
    const ctx = this.getUIContext().getHostContext();
    if (ctx === null || ctx === undefined) {
      hilog.error(DOMAIN, TAG, "Context is null, cannot start scan");
      return;
    }

    const options: scanBarcode.ScanOptions = {
      scanTypes: [scanCore.ScanType.ALL],
      enableMultiMode: false,
      enableAlbum: true
    };

    scanBarcode.startScanForResult(ctx, options).then(
      (result: scanBarcode.ScanResult): void => {
        this.scanResult = result.originalValue;
        this.resultCodeType = ScanTool.formatScanType(result.scanType);
        this.hasResult = true;
        hilog.info(DOMAIN, TAG, "Scan ok: %{public}s", result.originalValue);
        this.onScanResult(result.originalValue);
      }
    ).catch(
      (_err: object): void => {
        // 1000500002 = 用户取消,静默处理
        hilog.info(DOMAIN, TAG, "Scan canceled or failed");
      }
    );
  }

  private static formatScanType(scanType: number): string {
    if (scanType === scanCore.ScanType.QR_CODE) {
      return "QR Code";
    }
    if (scanType === scanCore.ScanType.EAN13_CODE) {
      return "EAN-13";
    }
    if (scanType === scanCore.ScanType.EAN8_CODE) {
      return "EAN-8";
    }
    if (scanType === scanCore.ScanType.CODE128_CODE) {
      return "Code 128";
    }
    if (scanType === scanCore.ScanType.CODE39_CODE) {
      return "Code 39";
    }
    if (scanType === scanCore.ScanType.UPC_A_CODE) {
      return "UPC-A";
    }
    if (scanType === scanCore.ScanType.UPC_E_CODE) {
      return "UPC-E";
    }
    if (scanType === scanCore.ScanType.PDF417_CODE) {
      return "PDF417";
    }
    if (scanType === scanCore.ScanType.DATAMATRIX_CODE) {
      return "Data Matrix";
    }
    if (scanType === scanCore.ScanType.AZTEC_CODE) {
      return "Aztec";
    }
    return "条码";
  }
}
