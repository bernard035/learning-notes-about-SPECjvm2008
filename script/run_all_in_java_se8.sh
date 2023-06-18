#!/bin/bash
# Java8不支持4个测试项 这个脚本用于手动指定其余的测试项
java -Djava.awt.headless=true -jar SPECjvm2008.jar -i console -ikv startup.helloworld startup.compress startup.crypto.aes startup.crypto.rsa startup.crypto.signverify startup.mpegaudio startup.scimark.fft startup.scimark.lu startup.scimark.monte_carlo startup.scimark.sor startup.scimark.sparse startup.serial startup.sunflow startup.xml.validation compress crypto.aes crypto.rsa crypto.signverify derby mpegaudio scimark.fft.large scimark.lu.large scimark.sor.large scimark.sparse.large scimark.fft.small scimark.lu.small scimark.sor.small scimark.sparse.small scimark.monte_carlo serial sunflow xml.validation
# -Djava.awt.headless=true 的作用是禁用图形化组件
# 是将Java AWT (Abstract Window Toolkit) 组件的默认行为更改为不启用显示设备，而是以非可视化模式运行
# 在没有图形界面的服务器环境下或某些嵌入式设备上，通过设置 -Djava.awt.headless=true 参数可以避免在调用包含AWT组件的代码时出现错误，例如 java.awt.HeadlessException 异常