// N1 (iStoreOS 192.168.1.149) PAC 自动代理
// 规则：内网 + 国内域名 → 直连；其余 → 走 N1 上的 Xray 代理（192.168.1.149:10808）
// 特点：末尾带 DIRECT 兜底 —— 即使 N1 盒子故障，浏览器也会自动回退直连，国内网站不受影响
function FindProxyForURL(url, host) {
    // 1) 内网 / 本机直连
    if (isPlainHostName(host) ||
        shExpMatch(host, "*.local") ||
        shExpMatch(host, "localhost") ||
        shExpMatch(host, "127.*") ||
        shExpMatch(host, "10.*") ||
        shExpMatch(host, "192.168.*") ||
        shExpMatch(host, "172.1[6-9].*") ||
        shExpMatch(host, "172.2[0-9].*") ||
        shExpMatch(host, "172.3[01].*"))
        return "DIRECT";

    // 2) 国内常见域名 / TLD / 阿里邮箱及企业域名直连
    if (shExpMatch(host, "*.cn") ||
        shExpMatch(host, "*.com.cn") ||
        shExpMatch(host, "*.baidu.com") ||
        shExpMatch(host, "*.bdstatic.com") ||
        shExpMatch(host, "*.qq.com") ||
        shExpMatch(host, "*.tencent.com") ||
        shExpMatch(host, "*.weixin.qq.com") ||
        shExpMatch(host, "*.taobao.com") ||
        shExpMatch(host, "*.tmall.com") ||
        shExpMatch(host, "*.alicdn.com") ||
        shExpMatch(host, "*.aliyun.com") ||
        shExpMatch(host, "*.aliyuncs.com") ||
        shExpMatch(host, "*.alibaba.com") ||
        shExpMatch(host, "*.alibaba-inc.com") ||
        shExpMatch(host, "*.alimail.com") ||
        shExpMatch(host, "*.alimail-cn.com") ||
        shExpMatch(host, "*.mxhichina.com") ||
        shExpMatch(host, "*.hichina.com") ||
        shExpMatch(host, "*.cloudmailbox.net") ||
        shExpMatch(host, "*.aliapp.org") ||
        shExpMatch(host, "*.mmstat.com") ||
        shExpMatch(host, "*.jskyzn.com") ||
        shExpMatch(host, "*.alipay.com") ||
        shExpMatch(host, "*.dingtalk.com") ||
        shExpMatch(host, "*.jd.com") ||
        shExpMatch(host, "*.163.com") ||
        shExpMatch(host, "*.126.com") ||
        shExpMatch(host, "*.bilibili.com") ||
        shExpMatch(host, "*.hdslb.com") ||
        shExpMatch(host, "*.zhihu.com") ||
        shExpMatch(host, "*.csdn.net") ||
        shExpMatch(host, "*.gitee.com") ||
        shExpMatch(host, "*.oschina.net") ||
        shExpMatch(host, "*.wps.cn") ||
        shExpMatch(host, "*.kingsoft.com") ||
        shExpMatch(host, "*.pcbeta.com") ||
        shExpMatch(host, "*.doubao.com") ||
        shExpMatch(host, "*.volces.com") ||
        shExpMatch(host, "*.bytedance.com") ||
        shExpMatch(host, "*.feishu.cn") ||
        shExpMatch(host, "*.larksuite.com") ||
        shExpMatch(host, "*.qichacha.com") ||
        shExpMatch(host, "*.tianyancha.com") ||
        shExpMatch(host, "*.mi.com") ||
        shExpMatch(host, "*.huawei.com") ||
        shExpMatch(host, "*.vmall.com") ||
        shExpMatch(host, "*.qcloud.com") ||
        shExpMatch(host, "*.myqcloud.com") ||
        shExpMatch(host, "*.u9.com") ||
        shExpMatch(host, "*.msftconnecttest.com") ||
        shExpMatch(host, "*.msftncsi.com"))
        return "DIRECT";

    // 3) 其余走 N1 代理（不可用时自动回退直连）
    return "PROXY 192.168.1.149:10808; SOCKS5 192.168.1.149:10808; DIRECT";
}
