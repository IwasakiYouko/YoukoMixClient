// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a zh_TW locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'zh_TW';

  static String m0(count) => "已選 ${count}";

  static String m1(name) => "已將 ${name} 添加到本地代理";

  static String m2(name) => "本地代理中已有 ${name}";

  static String m3(count, skipped) => "將添加 ${count} 項，跳過 ${skipped} 項已存在";

  static String m4(detail) => "清除數據失敗：${detail}";

  static String m5(code) =>
      "Windows 拒絕運行 YoukoMixCore.exe（錯誤 ${code}）。智能應用控制、AppLocker 等應用控制策略會攔截未簽名程式，請在該策略中放行 人間之里 或關閉策略後重試。";

  static String m6(name) =>
      "應用連續兩次未能完成啟動。為打斷崩潰循環，已取消選中設定 ${name}，並跳過本次自動設定，你可以隨時重新選中它。";

  static String m7(url) => "是否要通過 ${url} 創建設定？";

  static String m8(count, label) =>
      "${Intl.plural(count, other: '自定义配置不支持子规则，已丢弃 ${label} 條 SUB-RULE 規則')}";

  static String m9(message) => "內核無法解析該代理：${message}";

  static String m10(proxy, target) =>
      "${proxy} 經 ${target} 撥號，而 ${target} 又會回到 ${proxy}，形成環路";

  static String m11(name) => "名稱 ${name} 已被其他代理或策略群組使用";

  static String m12(path) => "策略群組之間存在循環引用：${path}";

  static String m13(name) => "空組兜底只能是代理，${name} 不存在或是策略群組";

  static String m14(name, message) => "${name}不是有效的正規表示式：${message}";

  static String m15(name) => "撥號代理 ${name} 不存在";

  static String m16(names) => "以下代理集不存在：${names}";

  static String m17(names) => "以下代理或策略不存在：${names}";

  static String m18(name) => "${name} 是內置策略名，不能在此使用";

  static String m19(count) => "${count} 項存在問題，應用設定可能失敗";

  static String m20(count) => "${count} 天前";

  static String m21(count) => "${count} 天前";

  static String m22(label) => "確定刪除選中的${label}嗎？";

  static String m23(label) => "確定刪除當前${label}嗎？";

  static String m24(label) => "${label}詳情";

  static String m25(name) => "經 ${name} 撥號會繞回使用它的代理，連線已中止";

  static String m26(label) => "${label}不能為空";

  static String m27(label) => "${label}當前已存在";

  static String m28(count) => "${count} 項失敗，點擊查看";

  static String m29(label, message) => "${label}：${message}";

  static String m30(name) => "${name} 已是最新版本";

  static String m31(name) => "${name} 已更新";

  static String m32(count) => "${count} 個";

  static String m33(count) => "${count} 超時";

  static String m34(action) => "已被“${action}”使用，保存後將移到這裡";

  static String m35(modifiers) => "至少包含 ${modifiers} 中的一個";

  static String m36(count) => "${count} 小時前";

  static String m37(count) => "${count} 小時前";

  static String m38(encoding) => "無法解碼 ${encoding}，顯示的是傳輸時的原始數據。";

  static String m39(memory, body) =>
      "達到此條數或佔滿 ${memory} 記憶體後，先丟棄最早的記錄。每段內容只保留前 ${body}。";

  static String m40(invalid, total) => "${total} 條中 ${invalid} 條無效";

  static String m41(target) => "${target} 是一個無效的策略";

  static String m42(proxyName) => "${proxyName} 是一個無效的代理";

  static String m43(providerName) => "${providerName} 是一個無效的代理集";

  static String m44(ruleSet) => "${ruleSet} 不是有效的規則集";

  static String m45(subRule) => "${subRule} 是一個無效的SUB_RULE";

  static String m46(count) => "${count} 項";

  static String m47(line, message) => "第 ${line} 行：${message}";

  static String m48(appName) =>
      "1. 打開 系統設定 > 隱私與安全性\n2. 選擇 定位服務\n3. 在右側列表中找到並勾選 ${appName}\n\n完成設定後，返回應用即可正常使用。感謝您的配合。";

  static String m49(label, max) => "${label}最多${max}個字元";

  static String m50(size) => "已釋放 ${size}";

  static String m51(count) => "${count} 分鐘前";

  static String m52(count) => "${count} 分鐘前";

  static String m53(fileName) =>
      "已將 ${fileName} 保存到“下載”。請在系統設定的“安全 › 加密與憑據 › 安裝憑證 › CA 憑證”中安裝。";

  static String m54(command) =>
      "Chrome 和 Firefox 使用自己的憑證庫，需要 certutil：${command}";

  static String m55(host) =>
      "要把 ${host} 加入主機名列表嗎？之後 人間之里 能讀取發往它的內容，包括 Cookie 和密碼。";

  static String m56(host) => "要把 -${host} 加到主機名列表頂部嗎？之後不再解密該主機。";

  static String m57(size) => "文件大於 ${size} MB";

  static String m58(stores) => "尚未加入：${stores}";

  static String m59(name) => "${name} 的腳本有變化，已關閉";

  static String m60(system) => "為 ${system} 編寫，部分行可能不適用於本設備。";

  static String m61(name) => "無法移除舊憑證 ${name}，請自行從信任的根憑證中移除。";

  static String m62(name) =>
      "舊憑證 ${name} 仍在系統信任的憑證中。請在 root 管理器中允許 人間之里 使用 root 後重新生成，或在其中移除“YoukoMix MITM CA”模塊並重新啟動。";

  static String m63(name) =>
      "請在系統設定的“安全 › 加密與憑據 › 信任的憑據 › 用戶”中移除舊憑證 ${name}，再安裝新憑證。";

  static String m64(section) => "不支持 [${section}] 段";

  static String m65(count) => "${count} 個月前";

  static String m66(count) => "${count} 個月前";

  static String m67(code) => "伺服器拒絕訪問（HTTP ${code}），連結可能已過期或憑據有誤";

  static String m68(code) => "伺服器拒絕了請求（HTTP ${code}）";

  static String m69(code) => "該地址下沒有內容（HTTP ${code}），請確認連結是否正確";

  static String m70(detail) => "網路請求失敗：${detail}";

  static String m71(code) => "伺服器出現問題（HTTP ${code}），請稍後再試";

  static String m72(label) => "暫無${label}";

  static String m73(label, min, max) => "${label}必須在 ${min} 到 ${max} 之間";

  static String m74(label) => "${label}必須為數字";

  static String m75(label) => "${label} 必須在 1024 到 49151 之間";

  static String m76(port) => "連接埠 ${port}";

  static String m77(days) => "剩余 ${days} 天";

  static String m78(date, days) => "${date} 到期，剩余 ${days} 天";

  static String m79(time) => "更新於 ${time}";

  static String m80(label, profiles) =>
      "${label} 仍被 ${profiles} 使用，刪除後這些設定會異常。確定刪除嗎？";

  static String m81(count, label) =>
      "${Intl.plural(count, other: '${label} 個代理')}";

  static String m82(name, count) => "${name} 等 ${count} 個代理";

  static String m83(removed) =>
      "以下代理將被刪除：${removed}。改了名字的行按新代理處理，自定義設定中對被刪除代理的引用會標為缺失。確定應用嗎？";

  static String m84(removed, added) =>
      "以下代理將被刪除：${removed}。以下代理將新增：${added}。改了名字的行按新代理處理，自定義設定中對被刪除代理的引用會標為缺失。確定應用嗎？";

  static String m85(label) =>
      "${label} 仍被當前設定的規則、策略群組、撥號代理、DNS 或 NTP 引用，刪除後這些引用會失效。確定刪除嗎？";

  static String m86(count, label) =>
      "${Intl.plural(count, other: '${label} 個策略群組')}";

  static String m87(count, label) =>
      "${Intl.plural(count, other: '${label} 條規則')}";

  static String m88(appName) => "${appName}（安全模式）";

  static String m89(count) => "${count} 秒";

  static String m90(count) => "${count} 項生效";

  static String m91(count) => "${count} 項異常";

  static String m92(count) => "${count} 項設定";

  static String m93(link) => "無法從 ${link} 中讀取代理";

  static String m94(label) => "${label}只能是一項";

  static String m95(value) => "峰值 ${value}";

  static String m96(value) => "累計 ${value}";

  static String m97(transport) => "${transport} 請求頭";

  static String m98(label) => "${label}必須為URL";

  static String m99(date) => "有效期至 ${date}";

  static String m100(count) => "${count} 年前";

  static String m101(count) => "${count} 年前";

  static String m102(minVersion) =>
      "當前版本低於站點最低要求版本（v${minVersion}），請立即更新客戶端以保證正常連線。";

  static String m103(online, limit) => "${online} / ${limit} 台";

  static String m104(day) => "當前周期可用流量已用完，將於每月 ${day} 日自動重設。";

  static String m105(level) => "Lv.${level}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "about": MessageLookupByLibrary.simpleMessage("關於"),
    "accessControl": MessageLookupByLibrary.simpleMessage("訪問控制"),
    "accessControlAllowDesc": MessageLookupByLibrary.simpleMessage(
      "只允許選中應用進入VPN",
    ),
    "accessControlDisabledDesc": MessageLookupByLibrary.simpleMessage(
      "應用訪問控制已關閉",
    ),
    "accessControlNotAllowDesc": MessageLookupByLibrary.simpleMessage(
      "選中應用將會被排除在VPN之外",
    ),
    "accessControlSelectedCount": m0,
    "account": MessageLookupByLibrary.simpleMessage("帳號"),
    "action": MessageLookupByLibrary.simpleMessage("操作"),
    "actionDelayTest": MessageLookupByLibrary.simpleMessage("測試全部延遲"),
    "actionDirectMode": MessageLookupByLibrary.simpleMessage("直連模式"),
    "actionGlobalMode": MessageLookupByLibrary.simpleMessage("全局模式"),
    "actionMode": MessageLookupByLibrary.simpleMessage("切換模式"),
    "actionProxy": MessageLookupByLibrary.simpleMessage("系統代理"),
    "actionRuleMode": MessageLookupByLibrary.simpleMessage("規則模式"),
    "actionStart": MessageLookupByLibrary.simpleMessage("啟動/停止"),
    "actionTun": MessageLookupByLibrary.simpleMessage("虛擬網卡"),
    "actionUpdateProfiles": MessageLookupByLibrary.simpleMessage("更新全部設定"),
    "actionView": MessageLookupByLibrary.simpleMessage("顯示/隱藏"),
    "add": MessageLookupByLibrary.simpleMessage("添加"),
    "addCustomProxy": MessageLookupByLibrary.simpleMessage("添加代理"),
    "addFilters": MessageLookupByLibrary.simpleMessage("添加篩選"),
    "addNodes": MessageLookupByLibrary.simpleMessage("添加節點"),
    "addOverrideEntry": MessageLookupByLibrary.simpleMessage("添加覆寫項"),
    "addProfile": MessageLookupByLibrary.simpleMessage("添加設定"),
    "addProxyGroup": MessageLookupByLibrary.simpleMessage("添加策略群組"),
    "addRule": MessageLookupByLibrary.simpleMessage("添加規則"),
    "addSettingEntry": MessageLookupByLibrary.simpleMessage("添加設定項"),
    "addSsid": MessageLookupByLibrary.simpleMessage("添加SSID"),
    "addToLocalProxies": MessageLookupByLibrary.simpleMessage("添加到本地代理"),
    "addedRules": MessageLookupByLibrary.simpleMessage("附加規則"),
    "addedToLocalProxies": m1,
    "additionalParameters": MessageLookupByLibrary.simpleMessage("附加參數"),
    "additionalPrefix": MessageLookupByLibrary.simpleMessage("名稱前綴"),
    "additionalSuffix": MessageLookupByLibrary.simpleMessage("名稱後綴"),
    "address": MessageLookupByLibrary.simpleMessage("地址"),
    "addressTip": MessageLookupByLibrary.simpleMessage("請輸入有效的WebDAV地址"),
    "advancedConfig": MessageLookupByLibrary.simpleMessage("進階設定"),
    "ageEncryptedProfile": MessageLookupByLibrary.simpleMessage("設定已加密"),
    "ageSecretKey": MessageLookupByLibrary.simpleMessage("age 私鑰"),
    "ageSecretKeyRequiredTip": MessageLookupByLibrary.simpleMessage(
      "該設定已用 age 加密，需要 age 私鑰才能解密",
    ),
    "agree": MessageLookupByLibrary.simpleMessage("同意"),
    "allReferencedProxies": MessageLookupByLibrary.simpleMessage("全部被引用的代理"),
    "allReferencedProxyProviders": MessageLookupByLibrary.simpleMessage(
      "全部被引用的代理集",
    ),
    "allowBypass": MessageLookupByLibrary.simpleMessage("允許應用繞過VPN"),
    "allowLan": MessageLookupByLibrary.simpleMessage("區域網路代理"),
    "allowedIps": MessageLookupByLibrary.simpleMessage("允許的 IP"),
    "alreadyInLocalProxies": m2,
    "answers": MessageLookupByLibrary.simpleMessage("應答"),
    "app": MessageLookupByLibrary.simpleMessage("應用"),
    "appAccessControl": MessageLookupByLibrary.simpleMessage("應用訪問控制"),
    "appIconDesign": MessageLookupByLibrary.simpleMessage("應用圖標設計"),
    "appProxiesEmpty": MessageLookupByLibrary.simpleMessage("暫無本地代理"),
    "appendSystemDns": MessageLookupByLibrary.simpleMessage("追加系統DNS"),
    "applied": MessageLookupByLibrary.simpleMessage("已應用"),
    "applyNow": MessageLookupByLibrary.simpleMessage("立即應用"),
    "arguments": MessageLookupByLibrary.simpleMessage("參數"),
    "authentication": MessageLookupByLibrary.simpleMessage("認證"),
    "authenticationSystemProxyDesc": MessageLookupByLibrary.simpleMessage(
      "認證啟用時，系統代理不生效。",
    ),
    "authorize": MessageLookupByLibrary.simpleMessage("授權"),
    "authorized": MessageLookupByLibrary.simpleMessage("已授權"),
    "auto": MessageLookupByLibrary.simpleMessage("自動"),
    "autoCheckUpdate": MessageLookupByLibrary.simpleMessage("自動檢查更新"),
    "autoCloseConnections": MessageLookupByLibrary.simpleMessage("自動關閉連線"),
    "autoInclude": MessageLookupByLibrary.simpleMessage("自動包含"),
    "autoLaunch": MessageLookupByLibrary.simpleMessage("開機自啟"),
    "autoRun": MessageLookupByLibrary.simpleMessage("自動運行"),
    "autoRunDesc": MessageLookupByLibrary.simpleMessage("自動運行會在打開應用時啟動代理。"),
    "autoSetSystemDns": MessageLookupByLibrary.simpleMessage("自動設定系統DNS"),
    "autoUpdate": MessageLookupByLibrary.simpleMessage("自動更新"),
    "autoUpdateInterval": MessageLookupByLibrary.simpleMessage("自動更新間隔"),
    "back": MessageLookupByLibrary.simpleMessage("返回"),
    "backgroundBlur": MessageLookupByLibrary.simpleMessage("背景模糊"),
    "backup": MessageLookupByLibrary.simpleMessage("備份"),
    "backupAndRestore": MessageLookupByLibrary.simpleMessage("備份與恢復"),
    "backupFromNewerVersion": MessageLookupByLibrary.simpleMessage(
      "該備份來自更高版本的應用，請先更新應用再恢復",
    ),
    "backupSuccess": MessageLookupByLibrary.simpleMessage("備份成功"),
    "basicInfo": MessageLookupByLibrary.simpleMessage("基礎資訊"),
    "basicStrategy": MessageLookupByLibrary.simpleMessage("基礎策略"),
    "batchImport": MessageLookupByLibrary.simpleMessage("批量導入"),
    "batchLineInputTip": MessageLookupByLibrary.simpleMessage("每行一項"),
    "batchLinkInputTip": MessageLookupByLibrary.simpleMessage("每行一個連結"),
    "batchPreviewTip": m3,
    "batchUrlInputTip": MessageLookupByLibrary.simpleMessage("每行一個URL"),
    "binaryData": MessageLookupByLibrary.simpleMessage("二進制數據"),
    "bind": MessageLookupByLibrary.simpleMessage("綁定"),
    "blacklistMode": MessageLookupByLibrary.simpleMessage("黑名單模式"),
    "blockQuic": MessageLookupByLibrary.simpleMessage("阻止 QUIC"),
    "bodyRewrite": MessageLookupByLibrary.simpleMessage("Body 重寫"),
    "brightness": MessageLookupByLibrary.simpleMessage("亮度"),
    "bypassDomain": MessageLookupByLibrary.simpleMessage("排除域名"),
    "bypassDomainDesc": MessageLookupByLibrary.simpleMessage(
      "排除域名僅在系統代理啟用時生效。",
    ),
    "bypassPrivateRoute": MessageLookupByLibrary.simpleMessage("繞過私有路由地址"),
    "cache": MessageLookupByLibrary.simpleMessage("快取"),
    "cacheAlgorithm": MessageLookupByLibrary.simpleMessage("快取算法"),
    "cacheCorrupt": MessageLookupByLibrary.simpleMessage("快取已損壞，是否清空？"),
    "cacheMaxSize": MessageLookupByLibrary.simpleMessage("快取大小"),
    "cameraPermissionDesc": MessageLookupByLibrary.simpleMessage(
      "請在系統設定中允許訪問相機以掃描QR Code，或從相冊選擇QR Code圖片。",
    ),
    "cameraPermissionRequired": MessageLookupByLibrary.simpleMessage("需要相機權限"),
    "cameraUnavailable": MessageLookupByLibrary.simpleMessage("相機不可用"),
    "cancel": MessageLookupByLibrary.simpleMessage("取消"),
    "cancelSelectAll": MessageLookupByLibrary.simpleMessage("取消全選"),
    "cannotSave": MessageLookupByLibrary.simpleMessage("無法保存"),
    "certificate": MessageLookupByLibrary.simpleMessage("憑證"),
    "changeProxyFailedTip": MessageLookupByLibrary.simpleMessage(
      "切換代理失敗，已恢復上一次的選擇",
    ),
    "changelogBreaking": MessageLookupByLibrary.simpleMessage("重大變更"),
    "changelogFeatures": MessageLookupByLibrary.simpleMessage("新功能"),
    "changelogFixes": MessageLookupByLibrary.simpleMessage("問題修復"),
    "changelogPerformance": MessageLookupByLibrary.simpleMessage("性能優化"),
    "changelogReverts": MessageLookupByLibrary.simpleMessage("已回滾"),
    "checkCertificate": MessageLookupByLibrary.simpleMessage("校驗 TLS 憑證"),
    "checkCertificateDesc": MessageLookupByLibrary.simpleMessage(
      "關閉憑證校驗後，訂閱和備份可能遭中間人攻擊。",
    ),
    "checkUpdate": MessageLookupByLibrary.simpleMessage("檢查更新"),
    "checkUpdateError": MessageLookupByLibrary.simpleMessage("當前應用已經是最新版了"),
    "cipher": MessageLookupByLibrary.simpleMessage("加密方式"),
    "clearData": MessageLookupByLibrary.simpleMessage("清除數據"),
    "clearDataAndExitTip": MessageLookupByLibrary.simpleMessage(
      "將刪除所有設定、設定和本地數據，隨後關閉應用。重新打開即可從頭開始。",
    ),
    "clearDataFailed": m4,
    "clearDnsCache": MessageLookupByLibrary.simpleMessage("清除DNS快取"),
    "clearDnsCacheFailed": MessageLookupByLibrary.simpleMessage("清除DNS快取失敗"),
    "clearSearch": MessageLookupByLibrary.simpleMessage("清除搜尋"),
    "clientFingerprint": MessageLookupByLibrary.simpleMessage("客戶端指紋"),
    "clipboardExport": MessageLookupByLibrary.simpleMessage("導出剪貼簿"),
    "clipboardImport": MessageLookupByLibrary.simpleMessage("剪貼簿導入"),
    "clipboardNoPackageNames": MessageLookupByLibrary.simpleMessage(
      "剪貼簿中沒有有效的包名",
    ),
    "clipboardWriteFailed": MessageLookupByLibrary.simpleMessage(
      "無法復制到剪貼簿，所選內容可能過大",
    ),
    "close": MessageLookupByLibrary.simpleMessage("關閉"),
    "closeConnection": MessageLookupByLibrary.simpleMessage("關閉連線"),
    "closeConnections": MessageLookupByLibrary.simpleMessage("關閉連線"),
    "color": MessageLookupByLibrary.simpleMessage("顏色"),
    "colorStyle": MessageLookupByLibrary.simpleMessage("配色風格"),
    "columns": MessageLookupByLibrary.simpleMessage("列數"),
    "compact": MessageLookupByLibrary.simpleMessage("緊湊"),
    "compatible": MessageLookupByLibrary.simpleMessage("兼容模式"),
    "confirm": MessageLookupByLibrary.simpleMessage("確定"),
    "confirmClearAllData": MessageLookupByLibrary.simpleMessage("確定要清除所有數據？"),
    "confirmDeleteProxyGroup": MessageLookupByLibrary.simpleMessage(
      "確定要刪除當前策略群組嗎？",
    ),
    "confirmExitWindow": MessageLookupByLibrary.simpleMessage("確定要退出當前窗口嗎？"),
    "confirmForceCrashCore": MessageLookupByLibrary.simpleMessage("確定要強制崩潰核心？"),
    "congestionControl": MessageLookupByLibrary.simpleMessage("擁塞控制"),
    "congestionController": MessageLookupByLibrary.simpleMessage("TCP 擁塞控制"),
    "congestionControllerDesc": MessageLookupByLibrary.simpleMessage(
      "TCP 擁塞控制僅在 mips 棧生效。",
    ),
    "connected": MessageLookupByLibrary.simpleMessage("已連線"),
    "connecting": MessageLookupByLibrary.simpleMessage("連線中…"),
    "connection": MessageLookupByLibrary.simpleMessage("連線"),
    "connectionStats": MessageLookupByLibrary.simpleMessage("連線統計"),
    "connectionStatsDesc": MessageLookupByLibrary.simpleMessage(
      "實時連線、最近請求、DNS查詢",
    ),
    "connections": MessageLookupByLibrary.simpleMessage("連線"),
    "connectivity": MessageLookupByLibrary.simpleMessage("連通性："),
    "content": MessageLookupByLibrary.simpleMessage("內容"),
    "contentNotEmpty": MessageLookupByLibrary.simpleMessage("內容不能為空"),
    "controlGlobalAddedRules": MessageLookupByLibrary.simpleMessage("控制全局附加規則"),
    "copy": MessageLookupByLibrary.simpleMessage("復制"),
    "copyAsBase64": MessageLookupByLibrary.simpleMessage("復制為 Base64"),
    "copyAsCurl": MessageLookupByLibrary.simpleMessage("復制為 cURL"),
    "copyDestination": MessageLookupByLibrary.simpleMessage("復制目標地址"),
    "copyEnvVar": MessageLookupByLibrary.simpleMessage("復制環境變量"),
    "copyHost": MessageLookupByLibrary.simpleMessage("復制主機"),
    "copyLink": MessageLookupByLibrary.simpleMessage("復制連結"),
    "copyRequest": MessageLookupByLibrary.simpleMessage("復制請求"),
    "copyResponse": MessageLookupByLibrary.simpleMessage("復制響應"),
    "copyResponseBody": MessageLookupByLibrary.simpleMessage("復制響應體"),
    "copySuccess": MessageLookupByLibrary.simpleMessage("復制成功"),
    "core": MessageLookupByLibrary.simpleMessage("內核"),
    "coreBlockedByPolicyTip": m5,
    "coreBlockedBySmartAppControlTip": MessageLookupByLibrary.simpleMessage(
      "Windows 智能應用控制攔截了未簽名的 YoukoMixCore.exe。請打開 Windows 安全中心 → 應用和瀏覽器控制 → 智能應用控制設定，選擇「關閉」後重新啟動 人間之里。智能應用控制關閉後無法再開啟，除非重裝 Windows。",
    ),
    "coreStatus": MessageLookupByLibrary.simpleMessage("核心狀態"),
    "country": MessageLookupByLibrary.simpleMessage("區域"),
    "crashDetected": MessageLookupByLibrary.simpleMessage("檢測到崩潰"),
    "crashDetectedTip": m6,
    "crashTest": MessageLookupByLibrary.simpleMessage("崩潰測試"),
    "create": MessageLookupByLibrary.simpleMessage("創建"),
    "createProfileFromUrlTip": m7,
    "creationTime": MessageLookupByLibrary.simpleMessage("創建時間"),
    "currentOutboundDesc": MessageLookupByLibrary.simpleMessage("含啟動鍵，不可移除"),
    "custom": MessageLookupByLibrary.simpleMessage("自定義"),
    "customColor": MessageLookupByLibrary.simpleMessage("自定義顏色"),
    "customImportDroppedSubRules": m8,
    "customIssueCoreRejected": m9,
    "customIssueDialerLoop": m10,
    "customIssueDuplicateName": m11,
    "customIssueEmptyName": MessageLookupByLibrary.simpleMessage("名稱為空"),
    "customIssueGroupLoop": m12,
    "customIssueInvalidEmptyFallback": m13,
    "customIssueInvalidFilter": m14,
    "customIssueMissingDialer": m15,
    "customIssueMissingProviders": m16,
    "customIssueMissingProxies": m17,
    "customIssueNoProxySource": MessageLookupByLibrary.simpleMessage(
      "未選擇任何代理或代理集，內核會拒絕該策略群組",
    ),
    "customIssueReservedName": m18,
    "customIssuesSummary": m19,
    "customProfile": MessageLookupByLibrary.simpleMessage("自定義"),
    "customResources": MessageLookupByLibrary.simpleMessage("自定義"),
    "cut": MessageLookupByLibrary.simpleMessage("剪切"),
    "dark": MessageLookupByLibrary.simpleMessage("深色"),
    "dashboard": MessageLookupByLibrary.simpleMessage("儀表板"),
    "dashboardAddableSection": MessageLookupByLibrary.simpleMessage("可添加"),
    "databaseWriteFailedTip": MessageLookupByLibrary.simpleMessage(
      "保存更改失敗，已回滾",
    ),
    "daysAgo": m20,
    "daysAgoShort": m21,
    "decryptUntrusted": MessageLookupByLibrary.simpleMessage("本機未信任時也解密"),
    "defaultNameserverDesc": MessageLookupByLibrary.simpleMessage(
      "用於解析其他 DNS 伺服器的域名，只能填寫 IP 地址。",
    ),
    "defaultSelected": MessageLookupByLibrary.simpleMessage("預設選中"),
    "defaultText": MessageLookupByLibrary.simpleMessage("預設"),
    "definitionNotMap": MessageLookupByLibrary.simpleMessage(
      "設定必須是包含 name 和 type 的 YAML 映射",
    ),
    "delay": MessageLookupByLibrary.simpleMessage("延遲"),
    "delayFailed": MessageLookupByLibrary.simpleMessage("失敗"),
    "delayTest": MessageLookupByLibrary.simpleMessage("延遲測試"),
    "delayTestTimeout": MessageLookupByLibrary.simpleMessage("延遲測試超時"),
    "delete": MessageLookupByLibrary.simpleMessage("刪除"),
    "deleteMultipTip": m22,
    "deleteTip": m23,
    "desc": MessageLookupByLibrary.simpleMessage("人間之里專屬跨平台網路加速客戶端，高速穩定、開箱即用。"),
    "destination": MessageLookupByLibrary.simpleMessage("目標地址"),
    "destinationGeoIP": MessageLookupByLibrary.simpleMessage("目標地理定位"),
    "destinationIPASN": MessageLookupByLibrary.simpleMessage("目標IP ASN"),
    "details": m24,
    "detectionTip": MessageLookupByLibrary.simpleMessage("依賴第三方api，僅供參考"),
    "developerMode": MessageLookupByLibrary.simpleMessage("開發者模式"),
    "developerModeEnableTip": MessageLookupByLibrary.simpleMessage("開發者模式已啟用。"),
    "dialerProxy": MessageLookupByLibrary.simpleMessage("撥號代理"),
    "dialerProxyLoopStopped": m25,
    "dialog": MessageLookupByLibrary.simpleMessage("對話框"),
    "direct": MessageLookupByLibrary.simpleMessage("直連"),
    "directNameserverDesc": MessageLookupByLibrary.simpleMessage(
      "用於解析直連連線的域名。",
    ),
    "disableIcmpForwarding": MessageLookupByLibrary.simpleMessage("禁用ICMP轉發"),
    "disableIcmpForwardingDesc": MessageLookupByLibrary.simpleMessage(
      "禁用 ICMP 轉發後由虛擬網卡直接應答 ping，ping 將不再顯示真實延遲。",
    ),
    "disableKeepAlive": MessageLookupByLibrary.simpleMessage("禁用 TCP 保持活動"),
    "disableUDP": MessageLookupByLibrary.simpleMessage("禁用UDP"),
    "disabled": MessageLookupByLibrary.simpleMessage("已關閉"),
    "discardChanges": MessageLookupByLibrary.simpleMessage("是否放棄更改？"),
    "disclaimer": MessageLookupByLibrary.simpleMessage("免責聲明"),
    "disclaimerAcceptContent": MessageLookupByLibrary.simpleMessage(
      "本聲明是對軟體性質、風險與責任的說明，不是 GPL-3.0 之外的附加條款，也不限制該協議授予你的運行、復制、修改和分發等任何權利；兩者不一致時，以 GPL-3.0 為准。",
    ),
    "disclaimerAcceptTitle": MessageLookupByLibrary.simpleMessage("與開源協議的關系"),
    "disclaimerAcknowledgeLabel": MessageLookupByLibrary.simpleMessage(
      "我已閱讀並理解此聲明",
    ),
    "disclaimerAcknowledgeTip": MessageLookupByLibrary.simpleMessage(
      "為確認你已知悉，請閱讀以下聲明並勾選下方選項：",
    ),
    "disclaimerAcknowledgeTitle": MessageLookupByLibrary.simpleMessage("確認聲明"),
    "disclaimerChangesContent": MessageLookupByLibrary.simpleMessage(
      "本聲明可能隨版本更新而修訂，以每個版本附帶的內容為准。",
    ),
    "disclaimerChangesTitle": MessageLookupByLibrary.simpleMessage("聲明變更"),
    "disclaimerDesc": MessageLookupByLibrary.simpleMessage(
      "在使用 人間之里（以下簡稱“本軟體”）前，請仔細閱讀並充分理解本聲明。點擊“同意”表示你已閱讀並理解以下內容；如不想繼續，可點擊“退出”。",
    ),
    "disclaimerLiabilityContent": MessageLookupByLibrary.simpleMessage(
      "在適用法律允許的最大範圍內，開發者及所有貢獻者均不對因使用或無法使用本軟體而產生的任何直接、間接、偶然、特殊、懲罰性或後果性損害承擔責任，包括但不限於數據丟失、設備損壞、網路異常、業務中斷、利潤損失或因此引起的任何法律糾紛，即使已被告知發生此類損害的可能性。",
    ),
    "disclaimerLiabilityTitle": MessageLookupByLibrary.simpleMessage("責任限制"),
    "disclaimerLicenseContent": MessageLookupByLibrary.simpleMessage(
      "本軟體以 GPL-3.0 協議開源，你可以依該協議運行、研究、修改和分發本軟體；分發本軟體或其修改版本時，須同樣以 GPL-3.0 協議提供源程式碼並保留原有的版權聲明。\n\n本軟體包含的第三方組件（包括 Clash.Meta 內核）分別遵循其各自的開源協議。基於本軟體修改或分發的版本所產生的任何問題，與原作者無關。",
    ),
    "disclaimerLicenseTitle": MessageLookupByLibrary.simpleMessage("開源協議"),
    "disclaimerNoServiceStatement": MessageLookupByLibrary.simpleMessage(
      "本軟體自身不提供任何代理伺服器、節點、訂閱、機場或網路接入服務，也不與任何此類服務的提供者存在合作、代理或擔保關系。",
    ),
    "disclaimerPrivacyContent": MessageLookupByLibrary.simpleMessage(
      "本軟體不會收集或上傳你的訂閱地址、節點資訊、設定內容、訪問的網站、連線記錄、流量內容和日誌，這些數據僅保存在你的設備本地，開發者無法獲取。\n\n本軟體只會在你使用相應功能時訪問外部網路，例如更新訂閱時訪問你提供的訂閱地址、檢查更新時訪問 GitHub。\n\n本軟體在所有平台上均未集成任何數據統計或崩潰上報服務。",
    ),
    "disclaimerPrivacyTitle": MessageLookupByLibrary.simpleMessage("數據收集與隱私"),
    "disclaimerResponsibilityContent": MessageLookupByLibrary.simpleMessage(
      "你應自行確認使用本軟體在你所在國家或地區是合法的，並對使用本軟體的全部行為及其後果獨立承擔法律責任。\n\n你導入的訂閱、節點與設定由你自行選擇和判斷，其來源是否合法、內容是否安全、服務是否穩定，均由你與相關提供者自行負責。",
    ),
    "disclaimerResponsibilityTitle": MessageLookupByLibrary.simpleMessage(
      "用戶責任",
    ),
    "disclaimerRestateHint": MessageLookupByLibrary.simpleMessage("在此輸入上述聲明"),
    "disclaimerRestateMismatch": MessageLookupByLibrary.simpleMessage(
      "與聲明內容不一致",
    ),
    "disclaimerRestateTip": MessageLookupByLibrary.simpleMessage(
      "為確認你已知悉，請在下方輸入框中完整復述以下聲明：",
    ),
    "disclaimerRestateTitle": MessageLookupByLibrary.simpleMessage("復述聲明"),
    "disclaimerSoftwareContent": MessageLookupByLibrary.simpleMessage(
      "本軟體是基於 Clash.Meta（mihomo）內核的開源網路代理客戶端，僅提供設定管理、規則分流與流量轉發等本地工具功能。",
    ),
    "disclaimerSoftwareTitle": MessageLookupByLibrary.simpleMessage("軟體性質"),
    "disclaimerThirdPartyContent": MessageLookupByLibrary.simpleMessage(
      "訂閱連結、設定檔、規則集、腳本、外部資源及外部連結均由第三方提供，開發者無法也不會對其合法性、准確性、安全性和可用性進行審查或擔保。\n\n因使用第三方內容導致的數據洩露、財產損失、帳號封禁或其他任何損失，由你與第三方自行解決，開發者不承擔任何責任。",
    ),
    "disclaimerThirdPartyTitle": MessageLookupByLibrary.simpleMessage("第三方內容"),
    "disclaimerUsageContent": MessageLookupByLibrary.simpleMessage(
      "任何人基於本軟體開展的商業活動，包括付費分發、捆綁銷售或作為商業服務的組成部分，均與本軟體的開發者無關，開發者不為其提供背書、支持或擔保。\n\n你須自行遵守所在國家或地區的法律法規，因違法使用本軟體產生的後果由你自行承擔。",
    ),
    "disclaimerUsageTitle": MessageLookupByLibrary.simpleMessage("使用說明"),
    "disclaimerWarrantyContent": MessageLookupByLibrary.simpleMessage(
      "本軟體按“現狀”和“可用”的原則提供，不附帶任何明示或默示的擔保，包括但不限於適銷性、特定用途適用性、不侵權以及持續可用、無錯誤、無安全漏洞的擔保。\n\n開發者不保證本軟體能滿足你的需求，也不保證本軟體的運行不會中斷或不會出現錯誤。",
    ),
    "disclaimerWarrantyTitle": MessageLookupByLibrary.simpleMessage("無擔保聲明"),
    "disconnected": MessageLookupByLibrary.simpleMessage("已斷開"),
    "discoverNewVersion": MessageLookupByLibrary.simpleMessage("發現新版本"),
    "dnsCacheCleared": MessageLookupByLibrary.simpleMessage("DNS快取已清除"),
    "dnsHijackDesc": MessageLookupByLibrary.simpleMessage(
      "未添加時劫持所有發往 53 連接埠的 DNS 請求（any:53）。",
    ),
    "dnsHijacking": MessageLookupByLibrary.simpleMessage("DNS劫持"),
    "dnsMode": MessageLookupByLibrary.simpleMessage("DNS模式"),
    "dnsOverrideDesc": MessageLookupByLibrary.simpleMessage(
      "添加的項會覆寫所有 URL 和文件設定的 DNS，未添加的項沿用設定自身的設定。自定義設定的 DNS 在其內容中設定。",
    ),
    "dnsQueries": MessageLookupByLibrary.simpleMessage("DNS查詢"),
    "docked": MessageLookupByLibrary.simpleMessage("固定"),
    "domain": MessageLookupByLibrary.simpleMessage("域名"),
    "done": MessageLookupByLibrary.simpleMessage("完成"),
    "download": MessageLookupByLibrary.simpleMessage("下載"),
    "downloadBandwidth": MessageLookupByLibrary.simpleMessage("下行頻寬"),
    "downloadingUpdate": MessageLookupByLibrary.simpleMessage("正在下載更新"),
    "duration": MessageLookupByLibrary.simpleMessage("時長"),
    "edit": MessageLookupByLibrary.simpleMessage("編輯"),
    "editDashboard": MessageLookupByLibrary.simpleMessage("編輯儀表板"),
    "editGlobalRules": MessageLookupByLibrary.simpleMessage("編輯全局規則"),
    "editProxy": MessageLookupByLibrary.simpleMessage("編輯代理"),
    "editProxyGroup": MessageLookupByLibrary.simpleMessage("編輯策略群組"),
    "editRule": MessageLookupByLibrary.simpleMessage("編輯規則"),
    "editSsid": MessageLookupByLibrary.simpleMessage("編輯SSID"),
    "editorUnavailable": MessageLookupByLibrary.simpleMessage("編輯器不可用"),
    "elapsed": MessageLookupByLibrary.simpleMessage("耗時"),
    "emptyFallback": MessageLookupByLibrary.simpleMessage("空組兜底"),
    "emptyTip": m26,
    "en": MessageLookupByLibrary.simpleMessage("英語"),
    "enabled": MessageLookupByLibrary.simpleMessage("已開啟"),
    "entries": MessageLookupByLibrary.simpleMessage("個條目"),
    "error": MessageLookupByLibrary.simpleMessage("錯誤"),
    "errorDetails": MessageLookupByLibrary.simpleMessage("錯誤詳情"),
    "es": MessageLookupByLibrary.simpleMessage("西班牙語"),
    "exclude": MessageLookupByLibrary.simpleMessage("從最近任務中隱藏"),
    "excludeDstPort": MessageLookupByLibrary.simpleMessage("排除目標連接埠"),
    "excludeFilter": MessageLookupByLibrary.simpleMessage("排除篩選"),
    "excludeInterface": MessageLookupByLibrary.simpleMessage("排除網卡"),
    "excludeSrcPort": MessageLookupByLibrary.simpleMessage("排除源連接埠"),
    "excludeSsids": MessageLookupByLibrary.simpleMessage("排除SSIDs"),
    "excludeSsidsDesc": MessageLookupByLibrary.simpleMessage(
      "連線到被排除 SSID 的 Wi-Fi 時，將會自動切換應用運行狀態。",
    ),
    "excludeUid": MessageLookupByLibrary.simpleMessage("排除用戶 ID"),
    "existsTip": m27,
    "exit": MessageLookupByLibrary.simpleMessage("退出"),
    "exitFullScreen": MessageLookupByLibrary.simpleMessage("退出全屏"),
    "exitNodes": MessageLookupByLibrary.simpleMessage("出口節點"),
    "expectedStatus": MessageLookupByLibrary.simpleMessage("預期狀態"),
    "expireTime": MessageLookupByLibrary.simpleMessage("到期時間"),
    "exportCertificate": MessageLookupByLibrary.simpleMessage("導出憑證"),
    "exportFile": MessageLookupByLibrary.simpleMessage("導出文件"),
    "exportHar": MessageLookupByLibrary.simpleMessage("導出 HAR"),
    "exportLogs": MessageLookupByLibrary.simpleMessage("導出日誌"),
    "exportSuccess": MessageLookupByLibrary.simpleMessage("導出成功"),
    "extend": MessageLookupByLibrary.simpleMessage("擴展"),
    "extendMode": MessageLookupByLibrary.simpleMessage("擴展模式"),
    "extendScript": MessageLookupByLibrary.simpleMessage("擴展腳本"),
    "externalController": MessageLookupByLibrary.simpleMessage("外部控制器"),
    "externalControllerDesc": MessageLookupByLibrary.simpleMessage(
      "外部控制器開啟後，可通過 9090 連接埠控制內核。",
    ),
    "externalControllerSecret": MessageLookupByLibrary.simpleMessage("外部控制器密鑰"),
    "externalLink": MessageLookupByLibrary.simpleMessage("外部連結"),
    "extraLarge": MessageLookupByLibrary.simpleMessage("超大"),
    "fade": MessageLookupByLibrary.simpleMessage("淡入"),
    "failedCount": m28,
    "failedItem": m29,
    "fakeipFilter": MessageLookupByLibrary.simpleMessage("Fake-IP過濾"),
    "fakeipFilterDesc": MessageLookupByLibrary.simpleMessage(
      "這些域名不使用 Fake-IP，返回真實 IP；過濾模式為 whitelist 時則只有它們使用 Fake-IP。",
    ),
    "fakeipFilterMode": MessageLookupByLibrary.simpleMessage("Fake-IP過濾模式"),
    "fakeipRange": MessageLookupByLibrary.simpleMessage("Fake-IP範圍"),
    "fakeipRange6": MessageLookupByLibrary.simpleMessage("Fake-IP範圍（IPv6）"),
    "fakeipTtl": MessageLookupByLibrary.simpleMessage("Fake-IP TTL"),
    "fallbackDesc": MessageLookupByLibrary.simpleMessage(
      "Nameserver 的結果被 Fallback 過濾判定為污染時，改用這些伺服器的結果。",
    ),
    "fallbackFilter": MessageLookupByLibrary.simpleMessage("Fallback過濾"),
    "fallbackFilterDomainDesc": MessageLookupByLibrary.simpleMessage(
      "這些域名直接使用 Fallback 解析。",
    ),
    "fallbackFilterGeositeDesc": MessageLookupByLibrary.simpleMessage(
      "屬於這些 GeoSite 分類的域名直接使用 Fallback 解析。",
    ),
    "fallbackFilterIpcidrDesc": MessageLookupByLibrary.simpleMessage(
      "Nameserver 返回這些網段內的 IP 時，改用 Fallback 的結果。",
    ),
    "file": MessageLookupByLibrary.simpleMessage("文件"),
    "fileIsUpdate": MessageLookupByLibrary.simpleMessage("文件有修改，是否保存修改"),
    "filter": MessageLookupByLibrary.simpleMessage("篩選"),
    "filters": MessageLookupByLibrary.simpleMessage("篩選"),
    "findProcessMode": MessageLookupByLibrary.simpleMessage("查找進程"),
    "floating": MessageLookupByLibrary.simpleMessage("懸浮"),
    "followProfile": MessageLookupByLibrary.simpleMessage("跟隨設定"),
    "followSystem": MessageLookupByLibrary.simpleMessage("跟隨系統"),
    "fontFamily": MessageLookupByLibrary.simpleMessage("字體"),
    "fontSize": MessageLookupByLibrary.simpleMessage("大小"),
    "forceDnsMapping": MessageLookupByLibrary.simpleMessage("強制DNS映射"),
    "forceDnsMappingDesc": MessageLookupByLibrary.simpleMessage(
      "強制 DNS 映射對通過 DNS 映射得到域名的連線也進行嗅探。",
    ),
    "forceDomain": MessageLookupByLibrary.simpleMessage("強制嗅探域名"),
    "forceDomainDesc": MessageLookupByLibrary.simpleMessage(
      "強制嗅探域名中的域名同樣會被嗅探，其余已有域名的連線不嗅探。",
    ),
    "forceRestartCoreTip": MessageLookupByLibrary.simpleMessage(
      "您確定要強制重新啟動核心嗎？",
    ),
    "fr": MessageLookupByLibrary.simpleMessage("法語"),
    "general": MessageLookupByLibrary.simpleMessage("常規"),
    "generalOverrideDesc": MessageLookupByLibrary.simpleMessage(
      "添加的項會覆寫所有設定的對應設定，未添加的項沿用設定自身的設定，設定未設定時使用內核預設值。",
    ),
    "generateCertificate": MessageLookupByLibrary.simpleMessage("生成憑證"),
    "geoResources": MessageLookupByLibrary.simpleMessage("Geo"),
    "geoSkipped": m30,
    "geoUpdated": m31,
    "geodataLoader": MessageLookupByLibrary.simpleMessage("Geo低記憶體模式"),
    "global": MessageLookupByLibrary.simpleMessage("全局"),
    "go": MessageLookupByLibrary.simpleMessage("前往"),
    "goDownload": MessageLookupByLibrary.simpleMessage("前往下載"),
    "goToConfigureAddedRules": MessageLookupByLibrary.simpleMessage("前往設定附加規則"),
    "goToConfigureScript": MessageLookupByLibrary.simpleMessage("前往設定腳本"),
    "grid": MessageLookupByLibrary.simpleMessage("網格"),
    "groupBy": MessageLookupByLibrary.simpleMessage("分類"),
    "groupCount": m32,
    "groupCountUnit": MessageLookupByLibrary.simpleMessage("個"),
    "groupTimeoutCount": m33,
    "hasCacheChange": MessageLookupByLibrary.simpleMessage("是否快取修改"),
    "hashByInUser": MessageLookupByLibrary.simpleMessage("按入站用戶哈希"),
    "headerRewrite": MessageLookupByLibrary.simpleMessage("Header 重寫"),
    "healthCheck": MessageLookupByLibrary.simpleMessage("健康檢查"),
    "helperCorruptTip": MessageLookupByLibrary.simpleMessage(
      "Helper 服務不可用，無法啟用 TUN 模式，請重新安裝 人間之里。",
    ),
    "hex": MessageLookupByLibrary.simpleMessage("十六進制"),
    "hideFromList": MessageLookupByLibrary.simpleMessage("從列表中隱藏"),
    "hideIp": MessageLookupByLibrary.simpleMessage("隱藏 IP"),
    "hidePassword": MessageLookupByLibrary.simpleMessage("隱藏密碼"),
    "hideTimeoutProxies": MessageLookupByLibrary.simpleMessage("隱藏超時代理"),
    "hopInterval": MessageLookupByLibrary.simpleMessage("跳躍間隔"),
    "host": MessageLookupByLibrary.simpleMessage("主機"),
    "hostname": MessageLookupByLibrary.simpleMessage("主機名"),
    "hotkeyConflictWith": m34,
    "hotkeyDesc": MessageLookupByLibrary.simpleMessage(
      "全局快捷鍵在窗口隱藏時依然生效，點擊操作即可錄制組合鍵。",
    ),
    "hotkeyManagement": MessageLookupByLibrary.simpleMessage("快捷鍵管理"),
    "hotkeyNeedsModifier": m35,
    "hotkeyNotSet": MessageLookupByLibrary.simpleMessage("未設定"),
    "hotkeyUnavailable": MessageLookupByLibrary.simpleMessage(
      "未能註冊，可能已被其他應用佔用",
    ),
    "hours": MessageLookupByLibrary.simpleMessage("小時"),
    "hoursAgo": m36,
    "hoursAgoShort": m37,
    "http2": MessageLookupByLibrary.simpleMessage("HTTP/2"),
    "httpBodyNotKept": MessageLookupByLibrary.simpleMessage("記憶體緊張時未記錄這段內容。"),
    "httpBodyProtobufGuess": MessageLookupByLibrary.simpleMessage(
      "按 Protobuf 解析，沒有 .proto：只有字段編號，類型是推測的。",
    ),
    "httpBodyTruncated": MessageLookupByLibrary.simpleMessage("只記錄了這段內容的開頭部分。"),
    "httpBodyUndecoded": m38,
    "httpCapture": MessageLookupByLibrary.simpleMessage("抓包"),
    "httpCaptureDesc": MessageLookupByLibrary.simpleMessage(
      "記錄“主機名”中列出的主機的請求，在連線詳情中查看。記錄只保存在記憶體中。",
    ),
    "httpCaptureLimit": MessageLookupByLibrary.simpleMessage("最多記錄條數"),
    "httpCaptureLimitDesc": m39,
    "httpCaptureNoHosts": MessageLookupByLibrary.simpleMessage(
      "未列出任何主機，不會記錄內容。請在 MITM 頁的“主機名”中添加，或在連線詳情中加入。",
    ),
    "httpCaptureOff": MessageLookupByLibrary.simpleMessage("抓包未開啟"),
    "httpExportPrivate": MessageLookupByLibrary.simpleMessage(
      "請求里可能有 Cookie、令牌、密碼和表單內容，分享前請確認內容和對象。",
    ),
    "httpExportPrivateTitle": MessageLookupByLibrary.simpleMessage("包含隱私資訊"),
    "httpRequestCleared": MessageLookupByLibrary.simpleMessage("這條請求的記錄已清除"),
    "httpRequests": MessageLookupByLibrary.simpleMessage("HTTP 請求"),
    "httpRequestsMissing": MessageLookupByLibrary.simpleMessage(
      "抓包開啟前發出或已被清除的請求不在列表中。",
    ),
    "httpsDecryption": MessageLookupByLibrary.simpleMessage("HTTPS 解密"),
    "hue": MessageLookupByLibrary.simpleMessage("色相"),
    "icon": MessageLookupByLibrary.simpleMessage("圖標"),
    "iconRecords": MessageLookupByLibrary.simpleMessage("圖標記錄"),
    "iconSets": MessageLookupByLibrary.simpleMessage("圖標集"),
    "iconSetsEmptyTip": MessageLookupByLibrary.simpleMessage(
      "暫無圖標集，可在「自定義設定資源 → 圖標集」中添加",
    ),
    "iconStyle": MessageLookupByLibrary.simpleMessage("圖標樣式"),
    "iconStyleFilled": MessageLookupByLibrary.simpleMessage("色塊"),
    "iconStyleHidden": MessageLookupByLibrary.simpleMessage("隱藏"),
    "iconStylePlain": MessageLookupByLibrary.simpleMessage("純圖標"),
    "iconUrl": MessageLookupByLibrary.simpleMessage("圖標連結"),
    "ignoreBatteryOptimization": MessageLookupByLibrary.simpleMessage("忽略電池優化"),
    "import": MessageLookupByLibrary.simpleMessage("導入"),
    "importConfigInvalid": MessageLookupByLibrary.simpleMessage("此文件不是可導入的設定"),
    "importConfigReplaceTip": MessageLookupByLibrary.simpleMessage(
      "導入會替換此設定現有的策略群組、規則和設定",
    ),
    "importFile": MessageLookupByLibrary.simpleMessage("通過文件導入"),
    "importFromLink": MessageLookupByLibrary.simpleMessage("從連結導入"),
    "importUrl": MessageLookupByLibrary.simpleMessage("通過URL導入"),
    "inProgress": MessageLookupByLibrary.simpleMessage("進行中"),
    "inbound": MessageLookupByLibrary.simpleMessage("入站"),
    "includeInterface": MessageLookupByLibrary.simpleMessage("包含網卡"),
    "includeInterfaceDesc": MessageLookupByLibrary.simpleMessage(
      "只有從包含網卡進入的流量經過虛擬網卡，設定後排除網卡不再生效。",
    ),
    "includeUid": MessageLookupByLibrary.simpleMessage("包含用戶 ID"),
    "infiniteTime": MessageLookupByLibrary.simpleMessage("長期有效"),
    "init": MessageLookupByLibrary.simpleMessage("初始化"),
    "initFailed": MessageLookupByLibrary.simpleMessage("啟動失敗"),
    "initFailedTip": MessageLookupByLibrary.simpleMessage(
      "人間之里 啟動時出錯，無法繼續運行。可以復制錯誤詳情用於反饋；如果問題反復出現，清除數據後通常可以重新啟動。",
    ),
    "initiator": MessageLookupByLibrary.simpleMessage("發起方"),
    "initiatorShort": MessageLookupByLibrary.simpleMessage("發起"),
    "inputProxyGroupName": MessageLookupByLibrary.simpleMessage("輸入策略群組名稱"),
    "inputRuleContent": MessageLookupByLibrary.simpleMessage("輸入規則內容"),
    "installCertificate": MessageLookupByLibrary.simpleMessage("安裝到系統"),
    "installCertificateSuccess": MessageLookupByLibrary.simpleMessage("憑證已安裝"),
    "installedAppsPermissionDeniedMessage":
        MessageLookupByLibrary.simpleMessage(
          "讀取應用列表權限已被拒絕，無法獲取已安裝的應用。請前往系統設定手動開啟。",
        ),
    "installedAppsPermissionDesc": MessageLookupByLibrary.simpleMessage(
      "當前系統在授權前不會提供已安裝的應用列表，授權後即可設定分應用代理。",
    ),
    "installedAppsPermissionRequired": MessageLookupByLibrary.simpleMessage(
      "需要讀取應用列表權限",
    ),
    "installedFonts": MessageLookupByLibrary.simpleMessage("已安裝字體"),
    "intelligentSelected": MessageLookupByLibrary.simpleMessage("智能選擇"),
    "interfaceName": MessageLookupByLibrary.simpleMessage("網卡名稱"),
    "interfaceNameMode": MessageLookupByLibrary.simpleMessage("出站網卡"),
    "interfaceNameModeClear": MessageLookupByLibrary.simpleMessage("清空"),
    "interfaceNameModeCustom": MessageLookupByLibrary.simpleMessage("自定義"),
    "interfaceNameModeFollow": MessageLookupByLibrary.simpleMessage("跟隨設定"),
    "internet": MessageLookupByLibrary.simpleMessage("互聯網"),
    "interval": MessageLookupByLibrary.simpleMessage("間隔"),
    "intranetIP": MessageLookupByLibrary.simpleMessage("內網 IP"),
    "invalidBackupFile": MessageLookupByLibrary.simpleMessage("無效備份文件"),
    "invalidCidrContent": MessageLookupByLibrary.simpleMessage(
      "請輸入 CIDR 格式的 IP 段，如 192.168.0.0/16",
    ),
    "invalidDscpContent": MessageLookupByLibrary.simpleMessage(
      "DSCP 標記不能超過 63",
    ),
    "invalidHostContent": MessageLookupByLibrary.simpleMessage("請輸入域名或 IP 地址"),
    "invalidIconSet": MessageLookupByLibrary.simpleMessage("不是有效的圖標集"),
    "invalidLinkTip": MessageLookupByLibrary.simpleMessage("不是有效的訂閱連結或代理分享連結"),
    "invalidListenContent": MessageLookupByLibrary.simpleMessage(
      "請輸入地址和連接埠，如 0.0.0.0:1053",
    ),
    "invalidNetworkContent": MessageLookupByLibrary.simpleMessage(
      "僅支持 tcp 或 udp",
    ),
    "invalidOfCount": m40,
    "invalidPolicy": m41,
    "invalidPortRangeContent": MessageLookupByLibrary.simpleMessage(
      "請輸入連接埠或範圍，如 443 或 8000-9000",
    ),
    "invalidProfileQrcode": MessageLookupByLibrary.simpleMessage(
      "該QR Code不包含設定檔連結",
    ),
    "invalidProxy": m42,
    "invalidProxyProvider": m43,
    "invalidRangeContent": MessageLookupByLibrary.simpleMessage(
      "請輸入數字或範圍，如 80 或 8000-9000，多個用 / 分隔",
    ),
    "invalidRuleSet": m44,
    "invalidSubRule": m45,
    "ipAddress": MessageLookupByLibrary.simpleMessage("IP 地址"),
    "ipAsn": MessageLookupByLibrary.simpleMessage("ASN"),
    "ipFlagAbuser": MessageLookupByLibrary.simpleMessage("濫用記錄"),
    "ipFlagProxy": MessageLookupByLibrary.simpleMessage("代理"),
    "ipFlagTor": MessageLookupByLibrary.simpleMessage("Tor"),
    "ipFlagVpn": MessageLookupByLibrary.simpleMessage("VPN"),
    "ipFlags": MessageLookupByLibrary.simpleMessage("命中標記"),
    "ipOrganization": MessageLookupByLibrary.simpleMessage("組織"),
    "ipQualityFailed": MessageLookupByLibrary.simpleMessage("類型查詢失敗"),
    "ipQualityGood": MessageLookupByLibrary.simpleMessage("優"),
    "ipQualityLevel": MessageLookupByLibrary.simpleMessage("等級"),
    "ipQualityNormal": MessageLookupByLibrary.simpleMessage("普通"),
    "ipQualityRetry": MessageLookupByLibrary.simpleMessage("重新查詢"),
    "ipQualityRisky": MessageLookupByLibrary.simpleMessage("風險"),
    "ipQualityShort": MessageLookupByLibrary.simpleMessage("質量"),
    "ipQualitySource": MessageLookupByLibrary.simpleMessage("採用來源"),
    "ipQualitySources": MessageLookupByLibrary.simpleMessage("各來源"),
    "ipSourceIpMismatch": MessageLookupByLibrary.simpleMessage("出站 IP 不一致"),
    "ipSourceNoType": MessageLookupByLibrary.simpleMessage("無法判定類型"),
    "ipSourceRateLimited": MessageLookupByLibrary.simpleMessage("限流"),
    "ipType": MessageLookupByLibrary.simpleMessage("類型"),
    "ipTypeBusiness": MessageLookupByLibrary.simpleMessage("商業"),
    "ipTypeHosting": MessageLookupByLibrary.simpleMessage("機房"),
    "ipTypeMobile": MessageLookupByLibrary.simpleMessage("移動網路"),
    "ipTypeResidential": MessageLookupByLibrary.simpleMessage("住宅"),
    "ipTypeUnknown": MessageLookupByLibrary.simpleMessage("類型未知"),
    "ipVersion": MessageLookupByLibrary.simpleMessage("IP 版本"),
    "ipv6Desc": MessageLookupByLibrary.simpleMessage("開啟 IPv6 後才會接收 IPv6 流量。"),
    "ipv6Timeout": MessageLookupByLibrary.simpleMessage("IPv6超時（毫秒）"),
    "itemsCount": m46,
    "ja": MessageLookupByLibrary.simpleMessage("日語"),
    "justNow": MessageLookupByLibrary.simpleMessage("剛剛"),
    "keepAliveIdle": MessageLookupByLibrary.simpleMessage("TCP 保持活動空閒時間"),
    "keepAliveIntervalDesc": MessageLookupByLibrary.simpleMessage("TCP保持活動間隔"),
    "key": MessageLookupByLibrary.simpleMessage("鍵"),
    "ko": MessageLookupByLibrary.simpleMessage("韓語"),
    "label": MessageLookupByLibrary.simpleMessage("標簽"),
    "language": MessageLookupByLibrary.simpleMessage("語言"),
    "large": MessageLookupByLibrary.simpleMessage("大"),
    "lastUpdated": MessageLookupByLibrary.simpleMessage("上次更新"),
    "launchInterrupted": MessageLookupByLibrary.simpleMessage("啟動未完成"),
    "launchInterruptedTip": MessageLookupByLibrary.simpleMessage(
      "應用上次在啟動過程中意外退出。已跳過本次自動設定，你可以手動啟動重試。",
    ),
    "layout": MessageLookupByLibrary.simpleMessage("布局"),
    "light": MessageLookupByLibrary.simpleMessage("淺色"),
    "lineIssueTip": m47,
    "lineWrap": MessageLookupByLibrary.simpleMessage("自動換行"),
    "link": MessageLookupByLibrary.simpleMessage("連結"),
    "liquidGlass": MessageLookupByLibrary.simpleMessage("液態玻璃"),
    "list": MessageLookupByLibrary.simpleMessage("列表"),
    "listen": MessageLookupByLibrary.simpleMessage("監聽"),
    "listenRoutingMark": MessageLookupByLibrary.simpleMessage("監聽路由標記"),
    "listenRoutingMarkDesc": MessageLookupByLibrary.simpleMessage(
      "監聽路由標記僅在 Linux 生效。",
    ),
    "liveConnections": MessageLookupByLibrary.simpleMessage("實時連線"),
    "loading": MessageLookupByLibrary.simpleMessage("加載中…"),
    "local": MessageLookupByLibrary.simpleMessage("本地"),
    "localImage": MessageLookupByLibrary.simpleMessage("本地圖片"),
    "localNetworkDeniedTip": MessageLookupByLibrary.simpleMessage(
      "本地網路權限被拒絕：已改用 gvisor 棧，區域網路無法訪問。",
    ),
    "localProxies": MessageLookupByLibrary.simpleMessage("本地代理"),
    "locationPermission": MessageLookupByLibrary.simpleMessage("位置權限"),
    "locationPermissionDeniedMessage": MessageLookupByLibrary.simpleMessage(
      "位置權限已被拒絕，無法獲取當前 Wi-Fi 名稱。請前往系統設定手動開啟位置權限。",
    ),
    "locationPermissionDesc": MessageLookupByLibrary.simpleMessage(
      "根據系統要求，獲取Wi-Fi名稱需要您授予位置權限。Android 上請選擇“始終允許”，否則應用在後台時無法獲取 Wi-Fi 名稱。",
    ),
    "locationPermissionGuide": m48,
    "locationPermissionRequired": MessageLookupByLibrary.simpleMessage(
      "需要位置權限",
    ),
    "log": MessageLookupByLibrary.simpleMessage("日誌"),
    "logLevel": MessageLookupByLibrary.simpleMessage("日誌等級"),
    "logcat": MessageLookupByLibrary.simpleMessage("日誌擷取"),
    "logcatDesc": MessageLookupByLibrary.simpleMessage("關閉日誌擷取會隱藏日誌入口。"),
    "logs": MessageLookupByLibrary.simpleMessage("日誌"),
    "logsAndDiagnostics": MessageLookupByLibrary.simpleMessage("日誌與診斷"),
    "logsTest": MessageLookupByLibrary.simpleMessage("日誌測試"),
    "loopback": MessageLookupByLibrary.simpleMessage("UWP 回環解鎖"),
    "loose": MessageLookupByLibrary.simpleMessage("寬松"),
    "mapLocal": MessageLookupByLibrary.simpleMessage("本地映射"),
    "matchCase": MessageLookupByLibrary.simpleMessage("區分大小寫"),
    "matchSourceIp": MessageLookupByLibrary.simpleMessage("匹配來源IP"),
    "matchTarget": MessageLookupByLibrary.simpleMessage("MATCH-TARGET"),
    "matchedRules": MessageLookupByLibrary.simpleMessage("命中的規則"),
    "maxFailedTimes": MessageLookupByLibrary.simpleMessage("最大失敗次數"),
    "maxLengthTip": m49,
    "maximize": MessageLookupByLibrary.simpleMessage("最大化"),
    "memoryAppResident": MessageLookupByLibrary.simpleMessage("常駐記憶體"),
    "memoryAppShared": MessageLookupByLibrary.simpleMessage("應用及共享"),
    "memoryCoreHeapIdle": MessageLookupByLibrary.simpleMessage("堆記憶體空閒"),
    "memoryCoreHeapInuse": MessageLookupByLibrary.simpleMessage("堆記憶體使用中"),
    "memoryCoreNotRunning": MessageLookupByLibrary.simpleMessage("內核未運行"),
    "memoryCoreRuntime": MessageLookupByLibrary.simpleMessage("運行時開銷"),
    "memoryCoreStack": MessageLookupByLibrary.simpleMessage("協程棧"),
    "memoryEstimateDesc": MessageLookupByLibrary.simpleMessage(
      "基於進程常駐記憶體估算，可能與系統顯示的數值不同。",
    ),
    "memoryEstimateSharedDesc": MessageLookupByLibrary.simpleMessage(
      "內核與應用運行在同一進程，內核部分按運行時統計估算，其余計入應用及共享記憶體。",
    ),
    "memoryInfo": MessageLookupByLibrary.simpleMessage("記憶體資訊"),
    "memoryInfoDesc": MessageLookupByLibrary.simpleMessage("應用與內核佔用的記憶體"),
    "memoryReleased": MessageLookupByLibrary.simpleMessage("記憶體已釋放"),
    "memoryReleasedSize": m50,
    "messageTest": MessageLookupByLibrary.simpleMessage("消息測試"),
    "messageTestTip": MessageLookupByLibrary.simpleMessage("這是一條消息。"),
    "method": MessageLookupByLibrary.simpleMessage("方法"),
    "minimize": MessageLookupByLibrary.simpleMessage("最小化"),
    "minimizeOnExit": MessageLookupByLibrary.simpleMessage("退出時最小化"),
    "minutes": MessageLookupByLibrary.simpleMessage("分鐘"),
    "minutesAgo": m51,
    "minutesAgoShort": m52,
    "mitm": MessageLookupByLibrary.simpleMessage("MITM"),
    "mitmAddLocalFile": MessageLookupByLibrary.simpleMessage("添加本地文件"),
    "mitmAddMapLocalRule": MessageLookupByLibrary.simpleMessage("添加本地映射規則"),
    "mitmAddRejectRule": MessageLookupByLibrary.simpleMessage("添加拒絕規則"),
    "mitmAttachments": MessageLookupByLibrary.simpleMessage("附件"),
    "mitmAttachmentsDesc": MessageLookupByLibrary.simpleMessage(
      "行內按檔案名稱引用附件，如 script-path=a.js。",
    ),
    "mitmCertificateAndroidReadyTip": MessageLookupByLibrary.simpleMessage(
      "只有信任用戶憑證的應用（多為瀏覽器）會被解密。",
    ),
    "mitmCertificateExportTip": MessageLookupByLibrary.simpleMessage(
      "導出後在要解密的設備上信任此憑證。",
    ),
    "mitmCertificateLinuxTip": MessageLookupByLibrary.simpleMessage(
      "Flatpak 版瀏覽器需要手動導入導出的憑證。",
    ),
    "mitmCertificateSavedTip": m53,
    "mitmCertutilMissing": m54,
    "mitmClientRefusedCertificate": MessageLookupByLibrary.simpleMessage(
      "客戶端拒絕了憑證。請安裝憑證；如果應用固定了憑證，請排除此主機。",
    ),
    "mitmDecryptHost": MessageLookupByLibrary.simpleMessage("解密此主機"),
    "mitmDecryptHostTip": m55,
    "mitmEnableTip": MessageLookupByLibrary.simpleMessage(
      "開啟後，人間之里 能讀取發往被解密主機的全部內容，包括 Cookie 和密碼。請只為需要改寫的主機開啟。",
    ),
    "mitmExcludeHost": MessageLookupByLibrary.simpleMessage("排除解密"),
    "mitmExcludeHostTip": m56,
    "mitmFileTooLarge": m57,
    "mitmHostnameDesc": MessageLookupByLibrary.simpleMessage(
      "以 - 開頭表示排除，第一條匹配的生效。",
    ),
    "mitmIgnoredLines": MessageLookupByLibrary.simpleMessage("忽略的行"),
    "mitmInstallSystemCaTip": MessageLookupByLibrary.simpleMessage(
      "檢測到 root，憑證將以 Magisk、KernelSU 或 APatch 模塊“YoukoMix MITM CA”加入系統信任的根憑證。之後本機所有應用都會信任它，持有其私鑰的人可以解密本機的 HTTPS 流量。如需撤銷，可重新生成憑證，或在 root 管理器中移除該模塊並重新啟動。若拒絕 root 授權，將改為安裝用戶憑證。",
    ),
    "mitmInstallUserCaTip": MessageLookupByLibrary.simpleMessage(
      "未檢測到 root，憑證只能安裝為用戶憑證。只有信任用戶憑證的應用（多為瀏覽器）會被解密，其他應用訪問列出的主機會失敗，請不要列出它們的主機。Android 11 起需在系統設定中手動完成安裝。",
    ),
    "mitmMissingStores": m58,
    "mitmModule": MessageLookupByLibrary.simpleMessage("模塊"),
    "mitmModuleInvalid": MessageLookupByLibrary.simpleMessage(
      "這不是 Surge 模塊、Loon 插件、Quantumult X 片段或 Stash 覆寫",
    ),
    "mitmModuleRulesDesc": MessageLookupByLibrary.simpleMessage(
      "分流規則排在設定自身的規則之前。",
    ),
    "mitmModuleScriptsChanged": m59,
    "mitmModuleSystemTip": m60,
    "mitmModules": MessageLookupByLibrary.simpleMessage("模塊"),
    "mitmNewModule": MessageLookupByLibrary.simpleMessage("新建模塊"),
    "mitmOldCertificateLeftTip": m61,
    "mitmOldSystemCertificateLeftTip": m62,
    "mitmRemoveOldCertificateTip": m63,
    "mitmRootPendingReboot": MessageLookupByLibrary.simpleMessage(
      "憑證將在重新啟動手機後生效。",
    ),
    "mitmRootUntilReboot": MessageLookupByLibrary.simpleMessage(
      "未找到可保留憑證的 Magisk、KernelSU 或 APatch，重新啟動手機後需要重新安裝。",
    ),
    "mitmRoutingRules": MessageLookupByLibrary.simpleMessage("分流規則"),
    "mitmRuleCopiedForStash": MessageLookupByLibrary.simpleMessage(
      "這個模塊是 Stash 覆寫，規則已復制，請手動添加。",
    ),
    "mitmRunScript": MessageLookupByLibrary.simpleMessage("立即運行"),
    "mitmScriptNoOutput": MessageLookupByLibrary.simpleMessage("腳本已運行完畢，沒有輸出"),
    "mitmScriptRisk": MessageLookupByLibrary.simpleMessage(
      "它的腳本能讀取並修改所匹配主機的流量，包括 Cookie 和令牌，還能自行傳送請求。只在信任其來源時開啟。",
    ),
    "mitmScriptRiskTitle": MessageLookupByLibrary.simpleMessage("運行此模塊的腳本？"),
    "mitmSkipConditional": MessageLookupByLibrary.simpleMessage("不支持條件重寫"),
    "mitmSkipDisabled": MessageLookupByLibrary.simpleMessage("已被參數關閉"),
    "mitmSkipEvent": MessageLookupByLibrary.simpleMessage("不支持此事件"),
    "mitmSkipJq": MessageLookupByLibrary.simpleMessage("不支持 jq 重寫"),
    "mitmSkipJsonBody": MessageLookupByLibrary.simpleMessage("不支持 JSON 正文重寫"),
    "mitmSkipNotDownloaded": MessageLookupByLibrary.simpleMessage("其文件尚未下載"),
    "mitmSkipPolicy": MessageLookupByLibrary.simpleMessage(
      "只支持 DIRECT 和 REJECT 策略",
    ),
    "mitmSkipRawHeader": MessageLookupByLibrary.simpleMessage(
      "不支持把全部標頭作為一段文本改寫",
    ),
    "mitmSkipRelativeData": MessageLookupByLibrary.simpleMessage(
      "此行引用的文件不是附件，請改用 URL 或添加為附件",
    ),
    "mitmSkipRule": MessageLookupByLibrary.simpleMessage("不支持此規則類型"),
    "mitmSkipScriptType": MessageLookupByLibrary.simpleMessage("不支持此類腳本"),
    "mitmSkipSection": m64,
    "mitmSkipSetting": MessageLookupByLibrary.simpleMessage("不支持此設定"),
    "mitmSkipUnreadable": MessageLookupByLibrary.simpleMessage("無法識別此行"),
    "mitmSystemStoreFailed": MessageLookupByLibrary.simpleMessage(
      "無法把憑證加入系統信任的根憑證",
    ),
    "mitmTrustChecking": MessageLookupByLibrary.simpleMessage("正在檢查…"),
    "mitmTrustNotInstalled": MessageLookupByLibrary.simpleMessage("未安裝"),
    "mitmTrustReady": MessageLookupByLibrary.simpleMessage("已信任"),
    "mitmTrustUntrusted": MessageLookupByLibrary.simpleMessage("未完全信任"),
    "mixedPort": MessageLookupByLibrary.simpleMessage("混合連接埠"),
    "mode": MessageLookupByLibrary.simpleMessage("模式"),
    "monochromeIcon": MessageLookupByLibrary.simpleMessage("單色圖標"),
    "monochromeScheme": MessageLookupByLibrary.simpleMessage("單色"),
    "monthsAgo": m65,
    "monthsAgoShort": m66,
    "more": MessageLookupByLibrary.simpleMessage("更多"),
    "name": MessageLookupByLibrary.simpleMessage("名稱"),
    "nameserverDesc": MessageLookupByLibrary.simpleMessage(
      "預設使用的 DNS 伺服器，如 223.5.5.5、tls://1.1.1.1、https://dns.google/dns-query。",
    ),
    "nameserverPolicyDesc": MessageLookupByLibrary.simpleMessage(
      "匹配的域名改用此處指定的 DNS 伺服器，優先於 Nameserver 和 Fallback。",
    ),
    "navigationBarStyle": MessageLookupByLibrary.simpleMessage("底欄"),
    "network": MessageLookupByLibrary.simpleMessage("網路"),
    "networkAccessDeniedError": m67,
    "networkBadResponseError": m68,
    "networkCancelledError": MessageLookupByLibrary.simpleMessage("請求已取消"),
    "networkConnectionError": MessageLookupByLibrary.simpleMessage(
      "無法連線到伺服器，請檢查網路連線或代理設定",
    ),
    "networkHostLookupError": MessageLookupByLibrary.simpleMessage(
      "無法解析伺服器地址，請確認連結正確且 DNS 可用",
    ),
    "networkName": MessageLookupByLibrary.simpleMessage("網路名稱"),
    "networkNotFoundError": m69,
    "networkRateLimitedError": MessageLookupByLibrary.simpleMessage(
      "請求過於頻繁（HTTP 429），請稍後再試",
    ),
    "networkRequestFailed": m70,
    "networkSecret": MessageLookupByLibrary.simpleMessage("網路密碼"),
    "networkServerError": m71,
    "networkSpeed": MessageLookupByLibrary.simpleMessage("網路速度"),
    "networkTakeover": MessageLookupByLibrary.simpleMessage("網路接管"),
    "networkTimeoutError": MessageLookupByLibrary.simpleMessage(
      "請求超時，請檢查網路或代理後重試",
    ),
    "networkTlsError": MessageLookupByLibrary.simpleMessage(
      "安全連線失敗，伺服器憑證可能無效，或連線被攔截",
    ),
    "networkType": MessageLookupByLibrary.simpleMessage("網路類型"),
    "nextMatch": MessageLookupByLibrary.simpleMessage("下一個匹配"),
    "no": MessageLookupByLibrary.simpleMessage("否"),
    "noData": MessageLookupByLibrary.simpleMessage("暫無數據"),
    "noInfo": MessageLookupByLibrary.simpleMessage("暫無資訊"),
    "noLongerRemind": MessageLookupByLibrary.simpleMessage("不再提示"),
    "noNetwork": MessageLookupByLibrary.simpleMessage("無網路"),
    "noNetworkApp": MessageLookupByLibrary.simpleMessage("無網路應用"),
    "noResolve": MessageLookupByLibrary.simpleMessage("不解析IP"),
    "noResolveHostname": MessageLookupByLibrary.simpleMessage("不解析主機名"),
    "noSearchResults": MessageLookupByLibrary.simpleMessage("沒有匹配的結果"),
    "nodes": MessageLookupByLibrary.simpleMessage("節點"),
    "nonTextProviderFile": MessageLookupByLibrary.simpleMessage("該外部資源不是文本文件"),
    "none": MessageLookupByLibrary.simpleMessage("無"),
    "notRunning": MessageLookupByLibrary.simpleMessage("未運行"),
    "notSelectedTip": MessageLookupByLibrary.simpleMessage("當前代理組無法選中"),
    "ntpInterval": MessageLookupByLibrary.simpleMessage("同步間隔（分鐘）"),
    "nullProfileDesc": MessageLookupByLibrary.simpleMessage("添加一個設定檔後即可開始使用"),
    "nullTip": m72,
    "numberRangeTip": m73,
    "numberTip": m74,
    "obfs": MessageLookupByLibrary.simpleMessage("混淆"),
    "obfsHost": MessageLookupByLibrary.simpleMessage("混淆主機"),
    "obfsMode": MessageLookupByLibrary.simpleMessage("混淆模式"),
    "obfsParam": MessageLookupByLibrary.simpleMessage("混淆參數"),
    "obfsPassword": MessageLookupByLibrary.simpleMessage("混淆密碼"),
    "onDemand": MessageLookupByLibrary.simpleMessage("按需運行"),
    "onlyStatisticsProxy": MessageLookupByLibrary.simpleMessage("僅統計代理流量"),
    "openSettings": MessageLookupByLibrary.simpleMessage("打開設定"),
    "optional": MessageLookupByLibrary.simpleMessage("可選"),
    "options": MessageLookupByLibrary.simpleMessage("選項"),
    "originalUrl": MessageLookupByLibrary.simpleMessage("原 URL"),
    "other": MessageLookupByLibrary.simpleMessage("其他"),
    "otherContributors": MessageLookupByLibrary.simpleMessage("其他貢獻者"),
    "outbound": MessageLookupByLibrary.simpleMessage("出站"),
    "outboundExit": MessageLookupByLibrary.simpleMessage("出口"),
    "outboundIp": MessageLookupByLibrary.simpleMessage("出站 IP"),
    "outboundMode": MessageLookupByLibrary.simpleMessage("出站模式"),
    "overrideDestination": MessageLookupByLibrary.simpleMessage("覆蓋目標地址"),
    "overrideEntries": MessageLookupByLibrary.simpleMessage("覆寫項"),
    "overview": MessageLookupByLibrary.simpleMessage("概覽"),
    "parsePureIp": MessageLookupByLibrary.simpleMessage("解析純IP"),
    "password": MessageLookupByLibrary.simpleMessage("密碼"),
    "paste": MessageLookupByLibrary.simpleMessage("貼上"),
    "peers": MessageLookupByLibrary.simpleMessage("初始節點"),
    "pickFromAlbum": MessageLookupByLibrary.simpleMessage("從相冊選擇"),
    "pinWindow": MessageLookupByLibrary.simpleMessage("窗口置頂"),
    "pleaseBindWebDAV": MessageLookupByLibrary.simpleMessage("請綁定WebDAV"),
    "pleaseEnterScriptName": MessageLookupByLibrary.simpleMessage("請輸入腳本名稱"),
    "pleaseUploadValidQrcode": MessageLookupByLibrary.simpleMessage(
      "請上傳有效的QR Code",
    ),
    "plugin": MessageLookupByLibrary.simpleMessage("插件"),
    "pluginCipher": MessageLookupByLibrary.simpleMessage("插件加密方式"),
    "pluginHost": MessageLookupByLibrary.simpleMessage("插件主機"),
    "pluginMode": MessageLookupByLibrary.simpleMessage("插件模式"),
    "pluginPassword": MessageLookupByLibrary.simpleMessage("插件密碼"),
    "pluginPath": MessageLookupByLibrary.simpleMessage("插件路徑"),
    "pluginUsername": MessageLookupByLibrary.simpleMessage("插件用戶名"),
    "port": MessageLookupByLibrary.simpleMessage("連接埠"),
    "portConflictTip": MessageLookupByLibrary.simpleMessage("請輸入不同的連接埠"),
    "portHopping": MessageLookupByLibrary.simpleMessage("連接埠跳躍"),
    "portTip": m75,
    "portValue": m76,
    "ports": MessageLookupByLibrary.simpleMessage("連接埠"),
    "preSharedKey": MessageLookupByLibrary.simpleMessage("預共享密鑰"),
    "preferred": MessageLookupByLibrary.simpleMessage("首選"),
    "prerequisites": MessageLookupByLibrary.simpleMessage("前置條件"),
    "pressKeyboard": MessageLookupByLibrary.simpleMessage("請按下組合鍵"),
    "preview": MessageLookupByLibrary.simpleMessage("預覽"),
    "previousMatch": MessageLookupByLibrary.simpleMessage("上一個匹配"),
    "privateKey": MessageLookupByLibrary.simpleMessage("私鑰"),
    "privateKeyPassphrase": MessageLookupByLibrary.simpleMessage("私鑰密碼"),
    "process": MessageLookupByLibrary.simpleMessage("進程"),
    "profile": MessageLookupByLibrary.simpleMessage("設定"),
    "profileAutoUpdateIntervalInvalidValidationDesc":
        MessageLookupByLibrary.simpleMessage("請輸入有效間隔時間格式"),
    "profileAutoUpdateIntervalNullValidationDesc":
        MessageLookupByLibrary.simpleMessage("請輸入自動更新間隔時間"),
    "profileDaysLeft": m77,
    "profileExpiresIn": m78,
    "profileHasUpdate": MessageLookupByLibrary.simpleMessage(
      "設定檔已經修改，是否關閉自動更新？",
    ),
    "profileNameNullValidationDesc": MessageLookupByLibrary.simpleMessage(
      "請輸入設定名稱",
    ),
    "profileSettingsDesc": MessageLookupByLibrary.simpleMessage(
      "僅作用於當前設定，未添加的項使用預設值。",
    ),
    "profileTunSettingsDesc": MessageLookupByLibrary.simpleMessage(
      "僅作用於當前設定，並優先於網路設定中的虛擬網卡覆寫項。",
    ),
    "profileUpdatedAt": m79,
    "profileUrlInvalidValidationDesc": MessageLookupByLibrary.simpleMessage(
      "請輸入有效設定URL",
    ),
    "profileUrlNullValidationDesc": MessageLookupByLibrary.simpleMessage(
      "請輸入設定URL",
    ),
    "profiles": MessageLookupByLibrary.simpleMessage("設定"),
    "profilesSort": MessageLookupByLibrary.simpleMessage("設定排序"),
    "project": MessageLookupByLibrary.simpleMessage("項目"),
    "protocol": MessageLookupByLibrary.simpleMessage("協議"),
    "protocolParam": MessageLookupByLibrary.simpleMessage("協議參數"),
    "protocolVersion": MessageLookupByLibrary.simpleMessage("協議版本"),
    "providerInUse": m80,
    "providerUrlTip": MessageLookupByLibrary.simpleMessage("僅支持遠程資源"),
    "providers": MessageLookupByLibrary.simpleMessage("外部資源"),
    "proxies": MessageLookupByLibrary.simpleMessage("代理"),
    "proxiesCount": m81,
    "proxiesProfileLabel": m82,
    "proxiesRemovedTip": m83,
    "proxiesReplacedTip": m84,
    "proxyChains": MessageLookupByLibrary.simpleMessage("代理鏈"),
    "proxyGroup": MessageLookupByLibrary.simpleMessage("策略群組"),
    "proxyGroupEmpty": MessageLookupByLibrary.simpleMessage("策略群組為空"),
    "proxyGroupInUse": m85,
    "proxyGroupsAfterStart": MessageLookupByLibrary.simpleMessage(
      "啟動後在這裡顯示策略群組",
    ),
    "proxyGroupsCount": m86,
    "proxyProviders": MessageLookupByLibrary.simpleMessage("代理集"),
    "proxyServerNameserverDesc": MessageLookupByLibrary.simpleMessage(
      "僅用於解析代理伺服器的域名。",
    ),
    "proxyServerNameserverPolicyDesc": MessageLookupByLibrary.simpleMessage(
      "匹配的代理伺服器域名改用此處指定的 DNS 伺服器，優先於 Proxy Server Nameserver。",
    ),
    "proxyType": MessageLookupByLibrary.simpleMessage("代理類型"),
    "pruneCache": MessageLookupByLibrary.simpleMessage("修剪快取"),
    "publicKey": MessageLookupByLibrary.simpleMessage("公鑰"),
    "pureBlack": MessageLookupByLibrary.simpleMessage("純黑"),
    "pureBlackMode": MessageLookupByLibrary.simpleMessage("純黑模式"),
    "qrcode": MessageLookupByLibrary.simpleMessage("QR Code"),
    "qrcodeDesc": MessageLookupByLibrary.simpleMessage("掃描QR Code獲取設定檔"),
    "qrcodeTooLongTip": MessageLookupByLibrary.simpleMessage(
      "連結過長，無法生成QR Code，請改用“復制連結”。",
    ),
    "quickActions": MessageLookupByLibrary.simpleMessage("快捷操作"),
    "quickEdit": MessageLookupByLibrary.simpleMessage("快速編輯"),
    "recentRequests": MessageLookupByLibrary.simpleMessage("最近請求"),
    "recommendedIcons": MessageLookupByLibrary.simpleMessage("推薦"),
    "recordType": MessageLookupByLibrary.simpleMessage("記錄類型"),
    "redirPort": MessageLookupByLibrary.simpleMessage("Redir連接埠"),
    "redo": MessageLookupByLibrary.simpleMessage("重做"),
    "regenerateCertificate": MessageLookupByLibrary.simpleMessage("重新生成憑證"),
    "regenerateCertificateTip": MessageLookupByLibrary.simpleMessage(
      "新憑證會替換當前憑證，人間之里 會盡量把當前憑證從本機信任的根憑證中移除。信任當前憑證的其他設備都需要安裝新憑證。",
    ),
    "regex": MessageLookupByLibrary.simpleMessage("正規表示式"),
    "releaseMemory": MessageLookupByLibrary.simpleMessage("釋放記憶體"),
    "releaseMemoryFailed": MessageLookupByLibrary.simpleMessage("釋放記憶體失敗"),
    "remote": MessageLookupByLibrary.simpleMessage("遠程"),
    "remoteDestination": MessageLookupByLibrary.simpleMessage("遠程目標"),
    "remoteDnsResolve": MessageLookupByLibrary.simpleMessage("遠程 DNS 解析"),
    "remove": MessageLookupByLibrary.simpleMessage("移除"),
    "rename": MessageLookupByLibrary.simpleMessage("重命名"),
    "replace": MessageLookupByLibrary.simpleMessage("替換"),
    "replaceAll": MessageLookupByLibrary.simpleMessage("全部替換"),
    "request": MessageLookupByLibrary.simpleMessage("請求"),
    "requestBody": MessageLookupByLibrary.simpleMessage("請求體"),
    "requestHeaders": MessageLookupByLibrary.simpleMessage("請求頭"),
    "requests": MessageLookupByLibrary.simpleMessage("請求"),
    "requestsAndUpdates": MessageLookupByLibrary.simpleMessage("請求與更新"),
    "required": MessageLookupByLibrary.simpleMessage("必填"),
    "reset": MessageLookupByLibrary.simpleMessage("重設"),
    "resetPageChangesTip": MessageLookupByLibrary.simpleMessage(
      "當前頁面存在更改，確定重設嗎？",
    ),
    "resetTip": MessageLookupByLibrary.simpleMessage("確定要重設嗎？"),
    "resourceUpdateInterval": MessageLookupByLibrary.simpleMessage("自動更新間隔"),
    "resourceUpdateIntervalTip": MessageLookupByLibrary.simpleMessage(
      "自動更新間隔必須大於0",
    ),
    "resources": MessageLookupByLibrary.simpleMessage("資源"),
    "respectRules": MessageLookupByLibrary.simpleMessage("遵守規則"),
    "respectRulesDesc": MessageLookupByLibrary.simpleMessage(
      "遵守規則使 DNS 連線遵守規則，需設定 Proxy Server Nameserver。",
    ),
    "response": MessageLookupByLibrary.simpleMessage("響應"),
    "responseBody": MessageLookupByLibrary.simpleMessage("響應體"),
    "responseCode": MessageLookupByLibrary.simpleMessage("響應碼"),
    "responseHeaders": MessageLookupByLibrary.simpleMessage("響應頭"),
    "restart": MessageLookupByLibrary.simpleMessage("重新啟動"),
    "restartCoreTip": MessageLookupByLibrary.simpleMessage("您確定要重新啟動核心嗎？"),
    "restore": MessageLookupByLibrary.simpleMessage("恢復"),
    "restoreAllData": MessageLookupByLibrary.simpleMessage("恢復所有數據"),
    "restoreOnlyConfig": MessageLookupByLibrary.simpleMessage("僅恢復設定檔"),
    "restoreStrategy": MessageLookupByLibrary.simpleMessage("恢復策略"),
    "restoreStrategyCompatible": MessageLookupByLibrary.simpleMessage("兼容"),
    "restoreStrategyOverride": MessageLookupByLibrary.simpleMessage("覆蓋"),
    "restoreSuccess": MessageLookupByLibrary.simpleMessage("恢復成功"),
    "result": MessageLookupByLibrary.simpleMessage("結果"),
    "retry": MessageLookupByLibrary.simpleMessage("重試"),
    "root": MessageLookupByLibrary.simpleMessage("Root"),
    "routeAddress": MessageLookupByLibrary.simpleMessage("路由地址"),
    "routeExcludeAddress": MessageLookupByLibrary.simpleMessage("排除路由地址"),
    "routingMark": MessageLookupByLibrary.simpleMessage("路由標記"),
    "ru": MessageLookupByLibrary.simpleMessage("俄語"),
    "rule": MessageLookupByLibrary.simpleMessage("規則"),
    "ruleActionAndDesc": MessageLookupByLibrary.simpleMessage("邏輯規則 AND"),
    "ruleActionDomainDesc": MessageLookupByLibrary.simpleMessage("匹配完整域名"),
    "ruleActionDomainKeywordDesc": MessageLookupByLibrary.simpleMessage(
      "匹配域名關鍵字",
    ),
    "ruleActionDomainRegexDesc": MessageLookupByLibrary.simpleMessage(
      "使用域名正規表示式匹配",
    ),
    "ruleActionDomainSuffixDesc": MessageLookupByLibrary.simpleMessage(
      "匹配域名後綴",
    ),
    "ruleActionDomainWildcardDesc": MessageLookupByLibrary.simpleMessage(
      "通配符匹配，僅支持*和?通配符",
    ),
    "ruleActionDscpDesc": MessageLookupByLibrary.simpleMessage(
      "匹配DSCP標記（僅限 tproxy udp 入站）",
    ),
    "ruleActionDstPortDesc": MessageLookupByLibrary.simpleMessage(
      "匹配請求目標連接埠範圍",
    ),
    "ruleActionGeoipDesc": MessageLookupByLibrary.simpleMessage(
      "匹配 IP 所屬國家程式碼",
    ),
    "ruleActionGeositeDesc": MessageLookupByLibrary.simpleMessage(
      "匹配 Geosite 內的域名",
    ),
    "ruleActionInNameDesc": MessageLookupByLibrary.simpleMessage("匹配入站名稱"),
    "ruleActionInPortDesc": MessageLookupByLibrary.simpleMessage("匹配入站連接埠"),
    "ruleActionInTypeDesc": MessageLookupByLibrary.simpleMessage("匹配入站類型"),
    "ruleActionInUserDesc": MessageLookupByLibrary.simpleMessage(
      "匹配入站用戶名，支持使用 / 分隔多個用戶名",
    ),
    "ruleActionIpAsnDesc": MessageLookupByLibrary.simpleMessage("匹配 IP 所屬 ASN"),
    "ruleActionIpCidr6Desc": MessageLookupByLibrary.simpleMessage(
      "匹配 IP 地址範圍，IP-CIDR6 只是一個別名",
    ),
    "ruleActionIpCidrDesc": MessageLookupByLibrary.simpleMessage("匹配 IP 地址範圍"),
    "ruleActionIpSuffixDesc": MessageLookupByLibrary.simpleMessage(
      "匹配 IP 後綴範圍",
    ),
    "ruleActionMatchDesc": MessageLookupByLibrary.simpleMessage("匹配所有請求，無需條件"),
    "ruleActionNetworkDesc": MessageLookupByLibrary.simpleMessage("匹配TCP或者UDP"),
    "ruleActionNotDesc": MessageLookupByLibrary.simpleMessage("邏輯規則 NOT"),
    "ruleActionOrDesc": MessageLookupByLibrary.simpleMessage("邏輯規則 OR"),
    "ruleActionProcessNameDesc": MessageLookupByLibrary.simpleMessage(
      "使用進程匹配，在Android平台可以匹配包名",
    ),
    "ruleActionProcessNameRegexDesc": MessageLookupByLibrary.simpleMessage(
      "使用進程名稱正規表示式匹配，在Android平台可以匹配包名",
    ),
    "ruleActionProcessNameWildcardDesc": MessageLookupByLibrary.simpleMessage(
      "使用進程名稱通配符匹配，僅支持*和?通配符",
    ),
    "ruleActionProcessPathDesc": MessageLookupByLibrary.simpleMessage(
      "使用完整進程路徑匹配",
    ),
    "ruleActionProcessPathRegexDesc": MessageLookupByLibrary.simpleMessage(
      "使用進程路徑正規表示式匹配",
    ),
    "ruleActionProcessPathWildcardDesc": MessageLookupByLibrary.simpleMessage(
      "使用進程路徑通配符匹配，僅支持*和?通配符",
    ),
    "ruleActionRematchNameDesc": MessageLookupByLibrary.simpleMessage(
      "匹配重匹配名稱，多個名稱用/分隔",
    ),
    "ruleActionRuleSetDesc": MessageLookupByLibrary.simpleMessage(
      "引用規則集合，需設定rule-providers",
    ),
    "ruleActionSrcGeoipDesc": MessageLookupByLibrary.simpleMessage(
      "匹配來源 IP 所屬國家程式碼",
    ),
    "ruleActionSrcIpAsnDesc": MessageLookupByLibrary.simpleMessage(
      "匹配來源 IP 所屬 ASN",
    ),
    "ruleActionSrcIpCidrDesc": MessageLookupByLibrary.simpleMessage(
      "匹配來源 IP 地址範圍",
    ),
    "ruleActionSrcIpSuffixDesc": MessageLookupByLibrary.simpleMessage(
      "匹配來源 IP 後綴範圍",
    ),
    "ruleActionSrcPortDesc": MessageLookupByLibrary.simpleMessage(
      "匹配請求來源連接埠範圍",
    ),
    "ruleActionSubRuleDesc": MessageLookupByLibrary.simpleMessage(
      "匹配至子規則，需要注意括號的使用",
    ),
    "ruleActionUidDesc": MessageLookupByLibrary.simpleMessage(
      "匹配 Linux USER ID",
    ),
    "ruleEmpty": MessageLookupByLibrary.simpleMessage("規則為空"),
    "ruleListInvalid": MessageLookupByLibrary.simpleMessage(
      "規則必須是 YAML 列表，每項一條規則，例如 - DOMAIN,example.com,DIRECT",
    ),
    "rulePresetBittorrentDirect": MessageLookupByLibrary.simpleMessage(
      "BT 下載直連",
    ),
    "rulePresetBlockDot": MessageLookupByLibrary.simpleMessage(
      "屏蔽 DNS over TLS",
    ),
    "rulePresetBlockLoopback": MessageLookupByLibrary.simpleMessage("防止代理回環"),
    "rulePresetBlockQuic": MessageLookupByLibrary.simpleMessage("屏蔽 QUIC"),
    "rulePresetBlockStun": MessageLookupByLibrary.simpleMessage("屏蔽 STUN"),
    "rulePresetLanDirect": MessageLookupByLibrary.simpleMessage("區域網路直連"),
    "rulePresetSystemServicesDirect": MessageLookupByLibrary.simpleMessage(
      "Apple 與 Microsoft 直連",
    ),
    "ruleProviders": MessageLookupByLibrary.simpleMessage("規則集"),
    "ruleSet": MessageLookupByLibrary.simpleMessage("規則集"),
    "ruleSetEmptyTip": MessageLookupByLibrary.simpleMessage("規則集中沒有可用的條目"),
    "ruleSetInvalidTip": MessageLookupByLibrary.simpleMessage("無法讀取該 mrs 文件"),
    "ruleSetMixedTip": MessageLookupByLibrary.simpleMessage(
      "規則集同時包含域名和 IP 段，無法判斷類型",
    ),
    "ruleTarget": MessageLookupByLibrary.simpleMessage("規則目標"),
    "ruleTextInvalid": MessageLookupByLibrary.simpleMessage(
      "規則必須以受支持的類型開頭，例如 DOMAIN,example.com,DIRECT",
    ),
    "rules": MessageLookupByLibrary.simpleMessage("規則"),
    "rulesCount": m87,
    "runTime": MessageLookupByLibrary.simpleMessage("運行時長"),
    "running": MessageLookupByLibrary.simpleMessage("運行中"),
    "runtimeConfig": MessageLookupByLibrary.simpleMessage("運行時設定"),
    "safeMode": MessageLookupByLibrary.simpleMessage("安全模式"),
    "safeModeAppTitle": m88,
    "saturation": MessageLookupByLibrary.simpleMessage("飽和度"),
    "save": MessageLookupByLibrary.simpleMessage("保存"),
    "saveChanges": MessageLookupByLibrary.simpleMessage("是否保存更改？"),
    "script": MessageLookupByLibrary.simpleMessage("腳本"),
    "scriptModeDesc": MessageLookupByLibrary.simpleMessage("腳本模式，使用擴展腳本改寫整個設定"),
    "scrollToSelected": MessageLookupByLibrary.simpleMessage("滾動到已選"),
    "search": MessageLookupByLibrary.simpleMessage("搜尋"),
    "seconds": MessageLookupByLibrary.simpleMessage("秒"),
    "secondsCount": m89,
    "secretKey": MessageLookupByLibrary.simpleMessage("密鑰"),
    "sectionsInEffect": m90,
    "select": MessageLookupByLibrary.simpleMessage("選中"),
    "selectAll": MessageLookupByLibrary.simpleMessage("全選"),
    "selectRuleSet": MessageLookupByLibrary.simpleMessage("請選擇規則集"),
    "selectSplitStrategy": MessageLookupByLibrary.simpleMessage("請選擇分流策略"),
    "send": MessageLookupByLibrary.simpleMessage("傳送"),
    "sendFromPhone": MessageLookupByLibrary.simpleMessage("從手機傳送"),
    "sendFromPhoneConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "導入手機發來的連結？",
    ),
    "sendFromPhoneNoNetwork": MessageLookupByLibrary.simpleMessage(
      "這台設備沒有連線區域網路",
    ),
    "sendFromPhonePageHint": MessageLookupByLibrary.simpleMessage(
      "訂閱連結或代理分享連結",
    ),
    "sendFromPhonePageSent": MessageLookupByLibrary.simpleMessage(
      "已傳送，請在另一台設備上確認導入。",
    ),
    "sendFromPhonePageTitle": MessageLookupByLibrary.simpleMessage(
      "把連結傳送到 人間之里",
    ),
    "sendFromPhonePermissionDenied": MessageLookupByLibrary.simpleMessage(
      "從手機接收連結需要「附近的設備」權限，人間之里 才能訪問區域網路。請在應用設定中開啟。",
    ),
    "sendFromPhoneTip": MessageLookupByLibrary.simpleMessage(
      "用手機相機掃描QR Code，在打開的頁面里貼上連結。兩台設備需要連在同一個網路。",
    ),
    "server": MessageLookupByLibrary.simpleMessage("伺服器"),
    "serviceAbnormalCount": m91,
    "serviceAllAvailable": MessageLookupByLibrary.simpleMessage("全部可用"),
    "serviceAvailable": MessageLookupByLibrary.simpleMessage("可用"),
    "serviceBlocked": MessageLookupByLibrary.simpleMessage("已被封禁"),
    "serviceCheckAll": MessageLookupByLibrary.simpleMessage("全部檢測"),
    "serviceComingSoon": MessageLookupByLibrary.simpleMessage("即將上線"),
    "serviceDisallowedIsp": MessageLookupByLibrary.simpleMessage("不允許的 ISP"),
    "serviceFailed": MessageLookupByLibrary.simpleMessage("檢測失敗"),
    "serviceManage": MessageLookupByLibrary.simpleMessage("管理服務"),
    "serviceOriginalsOnly": MessageLookupByLibrary.simpleMessage("僅限自制內容"),
    "servicePending": MessageLookupByLibrary.simpleMessage("待檢測"),
    "serviceRestricted": MessageLookupByLibrary.simpleMessage("訪問受限"),
    "serviceShownOnDashboard": MessageLookupByLibrary.simpleMessage("顯示在儀表板"),
    "serviceStatus": MessageLookupByLibrary.simpleMessage("服務狀態"),
    "serviceUnavailable": MessageLookupByLibrary.simpleMessage("不可用"),
    "serviceUnsupportedRegion": MessageLookupByLibrary.simpleMessage("地區不支持"),
    "settingEntries": MessageLookupByLibrary.simpleMessage("設定項"),
    "settings": MessageLookupByLibrary.simpleMessage("設定"),
    "settingsCount": m92,
    "shareLinkUnreadable": m93,
    "shareLinksInvalid": MessageLookupByLibrary.simpleMessage("無法從連結中讀取代理"),
    "shareQrcodeTip": MessageLookupByLibrary.simpleMessage(
      "在另一台設備上用 人間之里 掃碼即可導入此設定。",
    ),
    "show": MessageLookupByLibrary.simpleMessage("顯示"),
    "showLess": MessageLookupByLibrary.simpleMessage("收起"),
    "showMore": MessageLookupByLibrary.simpleMessage("展開"),
    "showNotificationStopAction": MessageLookupByLibrary.simpleMessage(
      "通知欄顯示停止按鈕",
    ),
    "showPassword": MessageLookupByLibrary.simpleMessage("顯示密碼"),
    "sidebar": MessageLookupByLibrary.simpleMessage("側邊欄"),
    "silentLaunch": MessageLookupByLibrary.simpleMessage("靜默啟動"),
    "singleImport": MessageLookupByLibrary.simpleMessage("單條導入"),
    "singleShareLinkOnly": MessageLookupByLibrary.simpleMessage(
      "這裡只能填寫一條連結，多條請在列表的快速編輯中填寫",
    ),
    "singleValueTip": m94,
    "size": MessageLookupByLibrary.simpleMessage("尺寸"),
    "skipCertVerify": MessageLookupByLibrary.simpleMessage("跳過憑證驗證"),
    "skipDomain": MessageLookupByLibrary.simpleMessage("跳過域名"),
    "skipDstAddress": MessageLookupByLibrary.simpleMessage("跳過目標地址"),
    "skipServerCertVerify": MessageLookupByLibrary.simpleMessage("跳過伺服器憑證驗證"),
    "skipSrcAddress": MessageLookupByLibrary.simpleMessage("跳過來源地址"),
    "slide": MessageLookupByLibrary.simpleMessage("滑動"),
    "sliders": MessageLookupByLibrary.simpleMessage("滑塊"),
    "sniffProtocols": MessageLookupByLibrary.simpleMessage("協議"),
    "sniffer": MessageLookupByLibrary.simpleMessage("域名嗅探"),
    "socksPort": MessageLookupByLibrary.simpleMessage("Socks連接埠"),
    "softStyle": MessageLookupByLibrary.simpleMessage("柔和"),
    "sort": MessageLookupByLibrary.simpleMessage("排序"),
    "source": MessageLookupByLibrary.simpleMessage("來源"),
    "sourceIp": MessageLookupByLibrary.simpleMessage("源IP"),
    "specialProxy": MessageLookupByLibrary.simpleMessage("特殊代理"),
    "specialRules": MessageLookupByLibrary.simpleMessage("特殊規則"),
    "spectrum": MessageLookupByLibrary.simpleMessage("光譜"),
    "speedStatistics": MessageLookupByLibrary.simpleMessage("網速統計"),
    "splitStrategy": MessageLookupByLibrary.simpleMessage("分流策略"),
    "splitStrategyNotEmpty": MessageLookupByLibrary.simpleMessage("分流策略不能為空"),
    "ssidsEmpty": MessageLookupByLibrary.simpleMessage("SSIDs為空"),
    "stackMode": MessageLookupByLibrary.simpleMessage("棧模式"),
    "stackTrace": MessageLookupByLibrary.simpleMessage("堆棧資訊"),
    "standard": MessageLookupByLibrary.simpleMessage("標准"),
    "standardModeDesc": MessageLookupByLibrary.simpleMessage(
      "標准模式，在設定的基礎上附加規則",
    ),
    "start": MessageLookupByLibrary.simpleMessage("啟動"),
    "startFromScratch": MessageLookupByLibrary.simpleMessage("從零開始"),
    "startVpn": MessageLookupByLibrary.simpleMessage("正在啟動VPN…"),
    "startupAndBackground": MessageLookupByLibrary.simpleMessage("啟動與後台"),
    "status": MessageLookupByLibrary.simpleMessage("狀態"),
    "statusDesc": MessageLookupByLibrary.simpleMessage("關閉 DNS 後將使用系統 DNS。"),
    "stop": MessageLookupByLibrary.simpleMessage("暫停"),
    "stopUpdateDownloadTip": MessageLookupByLibrary.simpleMessage("要停止下載更新嗎？"),
    "stopVpn": MessageLookupByLibrary.simpleMessage("正在停止VPN…"),
    "strategy": MessageLookupByLibrary.simpleMessage("策略"),
    "strictRoute": MessageLookupByLibrary.simpleMessage("嚴格路由"),
    "strictRouteDesc": MessageLookupByLibrary.simpleMessage(
      "嚴格路由防止 DNS 等流量繞過虛擬網卡，關閉 IPv6 時會阻斷本機的 IPv6 連線。",
    ),
    "style": MessageLookupByLibrary.simpleMessage("風格"),
    "submit": MessageLookupByLibrary.simpleMessage("提交"),
    "subscriptionInfo": MessageLookupByLibrary.simpleMessage("訂閱資訊"),
    "sudoPasswordTitle": MessageLookupByLibrary.simpleMessage("輸入 sudo 密碼"),
    "suspended": MessageLookupByLibrary.simpleMessage("掛起中…"),
    "switchProfile": MessageLookupByLibrary.simpleMessage("切換設定"),
    "sync": MessageLookupByLibrary.simpleMessage("同步"),
    "system": MessageLookupByLibrary.simpleMessage("系統"),
    "systemApp": MessageLookupByLibrary.simpleMessage("系統應用"),
    "systemProxy": MessageLookupByLibrary.simpleMessage("系統代理"),
    "tab": MessageLookupByLibrary.simpleMessage("標簽頁"),
    "tabAnimation": MessageLookupByLibrary.simpleMessage("選項卡動畫"),
    "tapIconToRetry": MessageLookupByLibrary.simpleMessage("點擊圖標重試"),
    "tapToAuthorize": MessageLookupByLibrary.simpleMessage("點擊授權"),
    "target": MessageLookupByLibrary.simpleMessage("目標"),
    "tcpConcurrent": MessageLookupByLibrary.simpleMessage("TCP並發"),
    "testInterval": MessageLookupByLibrary.simpleMessage("測試間隔"),
    "testUrl": MessageLookupByLibrary.simpleMessage("測速連結"),
    "testWhenUsed": MessageLookupByLibrary.simpleMessage("使用時測試"),
    "textScale": MessageLookupByLibrary.simpleMessage("文本縮放"),
    "textScalePreview": MessageLookupByLibrary.simpleMessage("應用內的文字將以這個大小顯示"),
    "theme": MessageLookupByLibrary.simpleMessage("主題"),
    "themeColor": MessageLookupByLibrary.simpleMessage("主題色彩"),
    "themeMode": MessageLookupByLibrary.simpleMessage("主題模式"),
    "tight": MessageLookupByLibrary.simpleMessage("緊湊"),
    "time": MessageLookupByLibrary.simpleMessage("時間"),
    "timeToFirstByte": MessageLookupByLibrary.simpleMessage("首字節耗時"),
    "timeout": MessageLookupByLibrary.simpleMessage("超時"),
    "tintedStyle": MessageLookupByLibrary.simpleMessage("氛圍"),
    "tip": MessageLookupByLibrary.simpleMessage("提示"),
    "toggle": MessageLookupByLibrary.simpleMessage("切換"),
    "tolerance": MessageLookupByLibrary.simpleMessage("容差"),
    "tools": MessageLookupByLibrary.simpleMessage("工具"),
    "torch": MessageLookupByLibrary.simpleMessage("手電筒"),
    "total": MessageLookupByLibrary.simpleMessage("總計"),
    "totalDownload": MessageLookupByLibrary.simpleMessage("下載總量"),
    "totalTraffic": MessageLookupByLibrary.simpleMessage("總流量"),
    "totalUpload": MessageLookupByLibrary.simpleMessage("上傳總量"),
    "tproxyPort": MessageLookupByLibrary.simpleMessage("Tproxy連接埠"),
    "traffic": MessageLookupByLibrary.simpleMessage("流量"),
    "trafficPeak": m95,
    "trafficTotal": m96,
    "trafficUsage": MessageLookupByLibrary.simpleMessage("流量統計"),
    "transport": MessageLookupByLibrary.simpleMessage("傳輸協議"),
    "transportHeaders": m97,
    "trustCertificate": MessageLookupByLibrary.simpleMessage("信任憑證"),
    "tun": MessageLookupByLibrary.simpleMessage("虛擬網卡"),
    "tunAuthorizationFailed": MessageLookupByLibrary.simpleMessage(
      "虛擬網卡授權失敗，已關閉。",
    ),
    "tunDesc": MessageLookupByLibrary.simpleMessage("虛擬網卡僅在管理員模式生效。"),
    "tunOverrideDesc": MessageLookupByLibrary.simpleMessage(
      "添加的項會覆寫所有設定的虛擬網卡設定，未添加的項沿用設定自身的設定。自定義設定自己添加的項優先。",
    ),
    "turnOff": MessageLookupByLibrary.simpleMessage("關閉"),
    "turnOn": MessageLookupByLibrary.simpleMessage("開啟"),
    "udpRelayMode": MessageLookupByLibrary.simpleMessage("UDP 中繼模式"),
    "udpTimeout": MessageLookupByLibrary.simpleMessage("UDP 超時"),
    "udpTimeoutDesc": MessageLookupByLibrary.simpleMessage(
      "UDP 超時以秒為單位，僅在 gvisor、system 和 mixed 棧生效。",
    ),
    "ultra": MessageLookupByLibrary.simpleMessage("極致"),
    "undo": MessageLookupByLibrary.simpleMessage("撤銷"),
    "unifiedDelay": MessageLookupByLibrary.simpleMessage("統一延遲"),
    "unknown": MessageLookupByLibrary.simpleMessage("未知"),
    "unknownNetworkError": MessageLookupByLibrary.simpleMessage("未知網路錯誤"),
    "unmaximize": MessageLookupByLibrary.simpleMessage("向下還原"),
    "unnamed": MessageLookupByLibrary.simpleMessage("未命名"),
    "unpinWindow": MessageLookupByLibrary.simpleMessage("取消置頂"),
    "update": MessageLookupByLibrary.simpleMessage("更新"),
    "updateDownloadFailed": MessageLookupByLibrary.simpleMessage("無法下載更新。"),
    "updateDownloadStarted": MessageLookupByLibrary.simpleMessage(
      "已開始下載更新，可在首頁查看進度",
    ),
    "updateDownloadTest": MessageLookupByLibrary.simpleMessage("更新下載測試"),
    "updateFailed": MessageLookupByLibrary.simpleMessage("更新失敗"),
    "updateInstallFailed": MessageLookupByLibrary.simpleMessage(
      "無法安裝更新，可以前往發布頁手動下載。",
    ),
    "updateNotVerified": MessageLookupByLibrary.simpleMessage("下載的更新未通過校驗。"),
    "updateReady": MessageLookupByLibrary.simpleMessage("更新已就緒"),
    "updateReadyTip": MessageLookupByLibrary.simpleMessage("更新已下載，點擊安裝"),
    "updateRestartTip": MessageLookupByLibrary.simpleMessage(
      "人間之里 將關閉以安裝更新，完成後自動重新打開。",
    ),
    "upload": MessageLookupByLibrary.simpleMessage("上傳"),
    "uploadBandwidth": MessageLookupByLibrary.simpleMessage("上行頻寬"),
    "url": MessageLookupByLibrary.simpleMessage("URL"),
    "urlRewrite": MessageLookupByLibrary.simpleMessage("URL 重寫"),
    "urlTip": m98,
    "useHosts": MessageLookupByLibrary.simpleMessage("使用Hosts"),
    "useSystemHosts": MessageLookupByLibrary.simpleMessage("使用系統Hosts"),
    "usedShort": MessageLookupByLibrary.simpleMessage("已用"),
    "usedTraffic": MessageLookupByLibrary.simpleMessage("已用流量"),
    "userAgent": MessageLookupByLibrary.simpleMessage("用戶代理"),
    "username": MessageLookupByLibrary.simpleMessage("用戶名"),
    "validUntil": m99,
    "value": MessageLookupByLibrary.simpleMessage("值"),
    "view": MessageLookupByLibrary.simpleMessage("查看"),
    "viewAll": MessageLookupByLibrary.simpleMessage("查看全部"),
    "virtualIpv4": MessageLookupByLibrary.simpleMessage("虛擬 IPv4"),
    "vividStyle": MessageLookupByLibrary.simpleMessage("鮮明"),
    "vpnConfigChangeDetected": MessageLookupByLibrary.simpleMessage(
      "VPN 相關設定已改動，點擊重新啟動",
    ),
    "webDAVConfiguration": MessageLookupByLibrary.simpleMessage("WebDAV設定"),
    "whitelistMode": MessageLookupByLibrary.simpleMessage("白名單模式"),
    "writeToSystem": MessageLookupByLibrary.simpleMessage("寫入系統"),
    "writeToSystemDesc": MessageLookupByLibrary.simpleMessage(
      "寫入系統會同時設定系統時鐘，Android 上不生效。",
    ),
    "yearsAgo": m100,
    "yearsAgoShort": m101,
    "yes": MessageLookupByLibrary.simpleMessage("是"),
    "youkomixAccount": MessageLookupByLibrary.simpleMessage("帳戶與訂閱"),
    "youkomixAnnouncements": MessageLookupByLibrary.simpleMessage("站點公告"),
    "youkomixAuthCode": MessageLookupByLibrary.simpleMessage("一次性授權碼"),
    "youkomixAuthCodeHint": MessageLookupByLibrary.simpleMessage(
      "貼上網頁生成的一次性授權碼",
    ),
    "youkomixBackToLogin": MessageLookupByLibrary.simpleMessage("返回密碼登入"),
    "youkomixBalance": MessageLookupByLibrary.simpleMessage("帳戶余額"),
    "youkomixCaptchaCode": MessageLookupByLibrary.simpleMessage("圖形驗證碼"),
    "youkomixCaptchaHint": MessageLookupByLibrary.simpleMessage("輸入圖片字元"),
    "youkomixCaptchaRefresh": MessageLookupByLibrary.simpleMessage("點擊重新整理"),
    "youkomixCaptchaRequiredTip": MessageLookupByLibrary.simpleMessage(
      "當前站點已開啟安全登入保護，請輸入下方圖形驗證碼",
    ),
    "youkomixCheckedIn": MessageLookupByLibrary.simpleMessage("今日已簽"),
    "youkomixCheckin": MessageLookupByLibrary.simpleMessage("每日簽到"),
    "youkomixCheckingIn": MessageLookupByLibrary.simpleMessage("簽到中…"),
    "youkomixClientUpdateRequiredDesc": m102,
    "youkomixClientUpdateRequiredTitle": MessageLookupByLibrary.simpleMessage(
      "需要升級客戶端版本",
    ),
    "youkomixClipboardAuthDetected": MessageLookupByLibrary.simpleMessage(
      "檢測到剪貼簿授權碼，點擊一鍵登入",
    ),
    "youkomixCopyDiagnostics": MessageLookupByLibrary.simpleMessage("復制診斷資訊"),
    "youkomixDeviceCount": m103,
    "youkomixDiagnosticsCopied": MessageLookupByLibrary.simpleMessage(
      "脫敏診斷資訊已復制，可直接貼上至工單",
    ),
    "youkomixEmail": MessageLookupByLibrary.simpleMessage("郵箱"),
    "youkomixEmailHint": MessageLookupByLibrary.simpleMessage("輸入註冊郵箱"),
    "youkomixEnterAuthCode": MessageLookupByLibrary.simpleMessage("輸入一次性授權碼"),
    "youkomixErrBadCertificate": MessageLookupByLibrary.simpleMessage(
      "面板安全憑證校驗失敗",
    ),
    "youkomixErrDecodeSubFailed": MessageLookupByLibrary.simpleMessage(
      "訂閱密文內容解碼失敗",
    ),
    "youkomixErrDecryptFailed": MessageLookupByLibrary.simpleMessage(
      "安全通道解密校驗失敗",
    ),
    "youkomixErrEmptyServerUrl": MessageLookupByLibrary.simpleMessage(
      "請輸入面板位址",
    ),
    "youkomixErrEmptySubscription": MessageLookupByLibrary.simpleMessage(
      "傳回的節點設定為空",
    ),
    "youkomixErrEnvelopeSigInvalid": MessageLookupByLibrary.simpleMessage(
      "加密回應數位簽章校驗失敗，連線已被攔截",
    ),
    "youkomixErrFetchCaptchaFailed": MessageLookupByLibrary.simpleMessage(
      "取得圖形驗證碼失敗，請重試",
    ),
    "youkomixErrInvalidEnvelope": MessageLookupByLibrary.simpleMessage(
      "加密回應信封格式無效",
    ),
    "youkomixErrInvalidEnvelopeBody": MessageLookupByLibrary.simpleMessage(
      "加密回應內容格式無效",
    ),
    "youkomixErrInvalidResponse": MessageLookupByLibrary.simpleMessage(
      "無法解析面板回應",
    ),
    "youkomixErrInvalidServerPubkey": MessageLookupByLibrary.simpleMessage(
      "伺服器安全公鑰格式無效",
    ),
    "youkomixErrInvalidServerUrl": MessageLookupByLibrary.simpleMessage(
      "面板位址格式無效，請使用 https:// 網域",
    ),
    "youkomixErrInvalidSignedBody": MessageLookupByLibrary.simpleMessage(
      "簽章載荷格式無效",
    ),
    "youkomixErrMissingServerPubkey": MessageLookupByLibrary.simpleMessage(
      "客戶端未設定預置安全公鑰，已拒絕建立安全通道",
    ),
    "youkomixErrMissingSignature": MessageLookupByLibrary.simpleMessage(
      "面板公開資料缺少有效的數位簽章",
    ),
    "youkomixErrNetworkTimeout": MessageLookupByLibrary.simpleMessage(
      "連線面板逾時，請檢查網路後重試",
    ),
    "youkomixErrNetworkUnreachable": MessageLookupByLibrary.simpleMessage(
      "無法連線面板伺服器，請檢查網路或面板位址",
    ),
    "youkomixErrParseSignedFailed": MessageLookupByLibrary.simpleMessage(
      "簽章載荷解析失敗",
    ),
    "youkomixErrRequestFailed": MessageLookupByLibrary.simpleMessage("請求失敗"),
    "youkomixErrServerPubkeyMismatch": MessageLookupByLibrary.simpleMessage(
      "伺服器安全公鑰不符，連線已被攔截",
    ),
    "youkomixErrServerUnavailable": MessageLookupByLibrary.simpleMessage(
      "面板服務暫時無法使用",
    ),
    "youkomixErrSignatureInvalid": MessageLookupByLibrary.simpleMessage(
      "面板數位簽章校驗未通過，回應可能遭竄改",
    ),
    "youkomixExpired": MessageLookupByLibrary.simpleMessage("方案已到期"),
    "youkomixForgotPassword": MessageLookupByLibrary.simpleMessage("找回密碼"),
    "youkomixFreeQuotaExhaustedDesc": MessageLookupByLibrary.simpleMessage(
      "當前周期可用流量已用完，將於下個周期自動重設。",
    ),
    "youkomixFreeQuotaExhaustedResetDesc": m104,
    "youkomixGotIt": MessageLookupByLibrary.simpleMessage("我知道了"),
    "youkomixLevelBadge": m105,
    "youkomixLoggingIn": MessageLookupByLibrary.simpleMessage("正在登入…"),
    "youkomixLogin": MessageLookupByLibrary.simpleMessage("登入"),
    "youkomixLogout": MessageLookupByLibrary.simpleMessage("登出"),
    "youkomixLogoutConfirm": MessageLookupByLibrary.simpleMessage(
      "登出後將斷開連線並清除本機快取設定，確定退出嗎？",
    ),
    "youkomixMfaCode": MessageLookupByLibrary.simpleMessage("驗證碼"),
    "youkomixMfaDesc": MessageLookupByLibrary.simpleMessage(
      "請輸入驗證器應用程式中的 6 位動態驗證碼",
    ),
    "youkomixMfaTitle": MessageLookupByLibrary.simpleMessage("兩步驟驗證"),
    "youkomixNeverExpire": MessageLookupByLibrary.simpleMessage("長期有效"),
    "youkomixNoAnnouncements": MessageLookupByLibrary.simpleMessage("暫無最新公告"),
    "youkomixOnlineDevices": MessageLookupByLibrary.simpleMessage("線上設備"),
    "youkomixOpenPanel": MessageLookupByLibrary.simpleMessage("打開面板"),
    "youkomixQuotaAlertTitle": MessageLookupByLibrary.simpleMessage("方案狀態提醒"),
    "youkomixQuotaExhaustedDesc": MessageLookupByLibrary.simpleMessage(
      "當前周期可用流量已耗盡，請前往控制面板重設或升級流量包。",
    ),
    "youkomixQuotaExpiredDesc": MessageLookupByLibrary.simpleMessage(
      "當前方案已到期或未開通，請前往控制面板購買或續費方案以恢復連線。",
    ),
    "youkomixQuotaNoticeTitle": MessageLookupByLibrary.simpleMessage("流量狀態提醒"),
    "youkomixQuotaWarningDesc": MessageLookupByLibrary.simpleMessage(
      "當前方案即將到期或剩余流量不足，建議提前續費以免影響連線。",
    ),
    "youkomixRegister": MessageLookupByLibrary.simpleMessage("註冊帳號"),
    "youkomixRenewPlan": MessageLookupByLibrary.simpleMessage("前往續費"),
    "youkomixScanAuthQr": MessageLookupByLibrary.simpleMessage("掃碼授權登入"),
    "youkomixServerUrl": MessageLookupByLibrary.simpleMessage("面板地址"),
    "youkomixServerUrlHint": MessageLookupByLibrary.simpleMessage(
      "https://example.com",
    ),
    "youkomixSessionExpired": MessageLookupByLibrary.simpleMessage(
      "登入狀態已過期，請重新登入",
    ),
    "youkomixSpeedLimit": MessageLookupByLibrary.simpleMessage("速率上限"),
    "youkomixSubChannel": MessageLookupByLibrary.simpleMessage("訂閱類型"),
    "youkomixSubChannelExclusive": MessageLookupByLibrary.simpleMessage("專屬訂閱"),
    "youkomixSubChannelExclusiveDesc": MessageLookupByLibrary.simpleMessage(
      "使用面板下發的專屬定制設定",
    ),
    "youkomixSubChannelStandard": MessageLookupByLibrary.simpleMessage("普通訂閱"),
    "youkomixSubChannelStandardDesc": MessageLookupByLibrary.simpleMessage(
      "使用帳戶對應的標准連線設定",
    ),
    "youkomixSubModeExclusive": MessageLookupByLibrary.simpleMessage("專屬訂閱已綁定"),
    "youkomixSubModeStandard": MessageLookupByLibrary.simpleMessage("標准訂閱模式"),
    "youkomixSubmitTicket": MessageLookupByLibrary.simpleMessage("提交工單"),
    "youkomixSupportAndPanel": MessageLookupByLibrary.simpleMessage("支持與面板"),
    "youkomixSyncNodes": MessageLookupByLibrary.simpleMessage("同步設定"),
    "youkomixSyncSuccess": MessageLookupByLibrary.simpleMessage("設定已同步"),
    "youkomixSyncing": MessageLookupByLibrary.simpleMessage("正在同步設定…"),
    "youkomixTagline": MessageLookupByLibrary.simpleMessage("專屬高速網路接入客戶端"),
    "youkomixTodayTraffic": MessageLookupByLibrary.simpleMessage("今日已用"),
    "youkomixUnlimited": MessageLookupByLibrary.simpleMessage("不限"),
    "youkomixUsageAndSpecs": MessageLookupByLibrary.simpleMessage("用量與規格"),
    "youkomixVerify": MessageLookupByLibrary.simpleMessage("驗證並登入"),
    "youkomixWebAuth": MessageLookupByLibrary.simpleMessage("網頁安全授權登入"),
    "youkomixWebAuthWaitingDesc": MessageLookupByLibrary.simpleMessage(
      "在瀏覽器確認授權後將自動返回客戶端；若未自動喚起，可在下方直接貼上一次性授權碼。",
    ),
    "youkomixWebAuthWaitingTitle": MessageLookupByLibrary.simpleMessage(
      "等待瀏覽器完成安全授權",
    ),
    "zhCN": MessageLookupByLibrary.simpleMessage("簡體中文"),
    "zhTW": MessageLookupByLibrary.simpleMessage("繁體中文"),
  };
}
