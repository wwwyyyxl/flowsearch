/**
 * @file FileTool.ets
 * @description 文件选择工具组件。S22 新增:接入 DocumentViewPicker 系统文件选择器。
 *
 * 鸿蒙文档依据:
 *   - @kit.CoreFileKit → picker.DocumentViewPicker(context).select(options)
 *   - 无需权限(系统授予 URI 临时读取权)
 *   - 返回 Array<string> 文件 URI
 *   - URI 格式: file://docs/storage/Users/.../filename.ext
 */

import { picker } from "@kit.CoreFileKit";
import { hilog } from "@kit.PerformanceAnalysisKit";

const TAG: string = "FileTool";
const DOMAIN: number = 0x0000;

@ComponentV2
export struct FileTool {
  @Local fileName: string = "";
  @Local fileUri: string = "";
  @Local hasFile: boolean = false;

  build() {
    Column({ space: 16 }) {
      // 提示文字
      Text("选择设备上的文件，查看文件信息")
        .fontSize($r("app.float.fs_text_body"))
        .fontColor($r("app.color.fs_color_text_secondary"))
        .textAlign(TextAlign.Center)
        .padding({ left: 32, right: 32 })

      // 选择文件按钮
      Button("选择文件")
        .fontSize($r("app.float.fs_text_body"))
        .fontColor($r("app.color.fs_color_text_inverse"))
        .backgroundColor($r("app.color.fs_color_primary"))
        .borderRadius($r("app.float.fs_radius_md"))
        .height($r("app.float.fs_height_button"))
        .width(200)
        .onClick((): void => { this.pickFile(); })

      // 结果展示区
      if (this.hasFile) {
        Column({ space: 8 }) {
          Text("已选择文件")
            .fontSize($r("app.float.fs_text_body_lg"))
            .fontWeight(FontWeight.Bold)
            .fontColor($r("app.color.fs_color_text_primary"))

          Text(this.fileName)
            .fontSize($r("app.float.fs_text_body"))
            .fontColor($r("app.color.fs_color_primary"))
            .fontWeight(FontWeight.Medium)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(this.fileUri)
            .fontSize($r("app.float.fs_text_caption"))
            .fontColor($r("app.color.fs_color_text_tertiary"))
            .maxLines(3)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
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

  private pickFile(): void {
    const ctx = this.getUIContext().getHostContext();
    if (ctx === null || ctx === undefined) {
      hilog.error(DOMAIN, TAG, "Context is null, cannot pick file");
      return;
    }

    const selectOptions: picker.DocumentSelectOptions = {
      maxSelectNumber: 1
    };
    const docPicker = new picker.DocumentViewPicker(ctx);

    docPicker.select(selectOptions).then(
      (uris: Array<string>): void => {
        if (uris.length > 0) {
          const uri: string = uris[0];
          this.fileUri = uri;
          this.fileName = FileTool.extractFileName(uri);
          this.hasFile = true;
          hilog.info(DOMAIN, TAG, "File picked: %{public}s", uri);
        }
      }
    ).catch(
      (_err: object): void => {
        // 用户取消或其他错误,静默处理
        hilog.info(DOMAIN, TAG, "File pick canceled or failed");
      }
    );
  }

  /**
   * 从文件 URI 中提取文件名。
   * URI 格式: file://docs/storage/Users/.../path/filename.ext
   * 取最后一个 "/" 之后的部分。
   */
  private static extractFileName(uri: string): string {
    const lastSlash: number = uri.lastIndexOf("/");
    if (lastSlash >= 0 && lastSlash < uri.length - 1) {
      return uri.substring(lastSlash + 1);
    }
    return uri;
  }
}
