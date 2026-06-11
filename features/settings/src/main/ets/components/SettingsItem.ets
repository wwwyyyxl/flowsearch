/**
 * @file SettingsItem.ets
 * @description 设置页列表项。4 种变体:text / switch / info / action。
 *
 * 参考 Stitch HTML 的 <button> / <div> 行:icon + title + value/switch/chevron。
 *
 * 设计要点:
 * - itemType 决定右侧内容:text→灰字+箭头 / switch→Toggle / info→灰字(不可点) / action→箭头
 * - showDivider 控制底部分割线(最后一项不显示)
 * - icon 用 emoji 字符(与 Stitch 的 Material Icons 对应)
 */

@ComponentV2
export struct SettingsItem {
  @Param icon: string = "";
  @Param title: string = "";
  @Param itemType: string = "text"; // "text" | "switch" | "info" | "action"
  @Param value: string = "";
  @Param switchOn: boolean = false;
  @Param showDivider: boolean = true;
  @Event onTap: () => void = (): void => {};
  @Event onSwitchChange: (on: boolean) => void = (_on: boolean): void => {};

  build() {
    Column() {
      Row() {
        // 左侧:icon + title
        Row({ space: 12 }) {
          Text(this.icon)
            .fontSize(18)
          Text(this.title)
            .fontSize($r("app.float.fs_text_body_lg"))
            .fontColor($r("app.color.fs_color_text_primary"))
        }
        .layoutWeight(1)

        // 右侧:按 itemType 分支
        if (this.itemType === "text") {
          this.buildTextRight()
        } else if (this.itemType === "switch") {
          this.buildSwitchRight()
        } else if (this.itemType === "info") {
          this.buildInfoRight()
        } else if (this.itemType === "action") {
          this.buildActionRight()
        }
      }
      .width("100%")
      .height($r("app.float.fs_height_list_single"))
      .padding({ left: $r("app.float.fs_space_lg"), right: $r("app.float.fs_space_lg") })
      .alignItems(VerticalAlign.Center)
      .onClick((): void => {
        if (this.itemType !== "switch" && this.itemType !== "info") {
          this.onTap();
        }
      })

      // 分割线
      if (this.showDivider) {
        Divider()
          .strokeWidth(0.5)
          .color($r("app.color.fs_color_border"))
          .opacity(0.5)
          .margin({ left: 48 })
      }
    }
    .width("100%")
  }

  @Builder
  buildTextRight() {
    Row({ space: 4 }) {
      Text(this.value)
        .fontSize($r("app.float.fs_text_body"))
        .fontColor($r("app.color.fs_color_text_secondary"))
      Text("›")
        .fontSize(18)
        .fontColor($r("app.color.fs_color_text_tertiary"))
    }
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  buildSwitchRight() {
    Toggle({ type: ToggleType.Switch, isOn: this.switchOn })
      .selectedColor($r("app.color.fs_color_primary"))
      .switchPointColor(Color.White)
      .onChange((isOn: boolean): void => {
        this.onSwitchChange(isOn);
      })
  }

  @Builder
  buildInfoRight() {
    Text(this.value)
      .fontSize($r("app.float.fs_text_body"))
      .fontColor($r("app.color.fs_color_text_secondary"))
  }

  @Builder
  buildActionRight() {
    Text("›")
      .fontSize(18)
      .fontColor($r("app.color.fs_color_text_tertiary"))
  }
}
