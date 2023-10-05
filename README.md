# SPECjvm2008 学习记录

## 初体验

### 安装

```sh
# WSL需要安装一些图形化的依赖
sudo apt install x11-apps  x11-session-utils dconf-editor gedit
# 现在可以在命令行下正常安装了，不会卡住
java -jar SPECjvm2008_1_01_setup.jar -i console
```

我的环境是：
![系统和硬件描述](https://img-blog.csdnimg.cn/d8ce0ed8cc7941c8be63c97412a51f20.png)

从这里开始就可以 HelloWorld 了
![HelloWorld](https://img-blog.csdnimg.cn/5850a6211f004bb6b47821c35decdb43.png)

### 运行

官方文档已经指出Java8不支持4个测试项，于是手动指定了其余的测试项，排除的测试项分别是  

- startup.compiler.compiler
- startup.compiler.sunflow
- compiler.sunflow
- compiler.sunflow

执行的脚本如下

```sh
java -jar SPECjvm2008.jar -i console -ikv startup.helloworld  startup.compress startup.crypto.aes startup.crypto.rsa startup.crypto.signverify startup.mpegaudio startup.scimark.fft startup.scimark.lu startup.scimark.monte_carlo startup.scimark.sor startup.scimark.sparse startup.serial startup.sunflow startup.xml.validation  compress crypto.aes crypto.rsa crypto.signverify derby mpegaudio scimark.fft.large scimark.lu.large scimark.sor.large scimark.sparse.large scimark.fft.small scimark.lu.small scimark.sor.small scimark.sparse.small scimark.monte_carlo serial sunflow xml.validation
```

### Full Run 输出

CPU: Inter i5 12500H  
OS: Windows 11   
JDK: Temurin OpenJDK 8

![full_run](https://img-blog.csdnimg.cn/9e79e4fecd0e45768156774304b03a32.jpeg)

### 火焰图

```sh
PID: 11308
[ perf record: Woken up 9071 times to write data ]
Warning:
22 out of order events recorded.
[ perf record: Captured and wrote 1041.264 MB perf.data (16674316 samples) ]
Command execution completed.
```

```bash
git clone https://github.com/brendangregg/FlameGraph.git

# 使用 perf script 命令将 perf.data 文件转换为文本格式的调用栈信息：
perf script -i perf.data > perf.txt
# 使用 stackcollapse-perf.pl 脚本将文本格式的调用栈信息转换为 FlameGraph 支持的格式：
./FlameGraph/stackcollapse-perf.pl perf.txt > perf.folded
# 使用 flamegraph.pl 脚本将转换后的调用栈信息生成火焰图：
./FlameGraph/flamegraph.pl perf.folded > perf.svg
```
通过perf在默认参数下收集Dragon在单次运行中得到的火焰图如下。

![通过perf在默认参数下收集Dragon在单次运行中得到的火焰图](https://img-blog.csdnimg.cn/783a836555e54a53b8efbeb0d8c700a5.png)

## Benchmark: compress 在多个JDK上的表现

### Environment: Info about JDK

|JDK|Version|JRE|VM|
|-|-|-|-|
|Oracle  | 1.8.0_202  |Java(TM) SE Runtime Environment (build 1.8.0_202-b08) |Java HotSpot(TM) 64-Bit Server VM (build 25.202-b08, mixed mode)|
|Adoptium Eclipse Temurin (Adopt OpenJDK)|1.8.0_372|OpenJDK Runtime Environment (Temurin)(build 1.8.0_372-b07)|OpenJDK 64-Bit Server VM (Temurin)(build 25.372-b07, mixed mode)|
|Bellsoft Liberica JDK|1.8.0_372|OpenJDK Runtime Environment (build 1.8.0_372-b07)|OpenJDK 64-Bit Server VM (build 25.372-b07, mixed mode)|
|Alibaba DragonWell|1.8.0_372|OpenJDK Runtime Environment (Alibaba Dragonwell Extended Edition 8.15.16) (build 1.8.0_372-b01)|OpenJDK 64-Bit Server VM (Alibaba Dragonwell Extended Edition 8.15.16) (build 25.372-b01, mixed mode)|
|Tencent Kona|1.8.0_372|OpenJDK Runtime Environment (Tencent Kona 8.0.14) (build 1.8.0_372-b1)|OpenJDK 64-Bit Server VM (Tencent Kona 8.0.14) (build 25.372-b1, mixed mode, sharing)|
|Huawei Bisheng|1.8.0_372|OpenJDK Runtime Environment BiSheng (build 1.8.0_372-b11)|OpenJDK 64-Bit Server VM BiSheng (build 25.372-b11, mixed mode)|

| JDK |  round 1 |round 2 |round 3 |round 4 |round 5 |mean|std|
|--|--|--|--|--|--|--|--|
| Oracle | 591.32  |611.16  |605.86  |585.12  |616.99  |602.09|13.44|
| Temurin| 603.07 |602.15  |604.48  |600.06  |610.53  |604.06|3.96|
|Liberica|618.89|612.94|618.06|595.21|607.24|610.47|9.72|
| DragonWell | 621.00  |614.98  |609.68  |609.13  |607.67  |612.49|5.50|
| Kona| 584.87 |586.79  |585.03  |604.21  |611.48  |594.48|12.49|
| Bisheng| 599.17  | 604.54  | 597.31  |594.10  |606.78  |600.38|5.21|

ops/m

其实在测试的时候发现有很多变量没有控制。比如持续测试机器发热CPU可能会降频，比如后台运行的应用程序等等

p_value:

![p_value](https://img-blog.csdnimg.cn/0102f4189d8948b881b51de5d18eb347.png)

test for homogeneity variances:

![homogeneity variances](https://img-blog.csdnimg.cn/4d494c411c944053a0bf75151d16e3a7.png)

这部分代码运行的结果实际上是 Welch's t-test
它假设两个样本的方差不相等，因此t值的自由度（degrees of freedom）将使用更加复杂的公式进行计算
在这种情况，`ttest_ind`函数将会产生更加保守的结果（更容易得出样本之间没有显著差异的结论）

### 更高频次的实验

在对于前述部分做数据T-test的时候，我注意到了每一组的方差齐性检验 (test for homogeneity variances) 都不通过。

> the assumptions to use t-tests
>
> - Independence 两个样本必须是独立的；
> - Normality 样本来自的总体必须近似服从正态分布(normally distributed)；
> - Homogeneity of Variances 方差齐性假设：两个样本的方差应相等，即方差齐性假设成立；

我在接下来的测试中提高了测试次数，提高测试次数可以增加样本量，从而使得统计推断更加准确。在进行方差齐性假设检验时，样本数量越多，检验结果的可靠性也越高。

下面的实验结果是通过下列命令测试得到的，我在WSL内使用`nice`命令`nice -n 20 java &`提升`java`进程的优先级（但可能还是在实体机上做测试比较有意义），我想我很快就会就能配置一个Linux to go，来解决这个问题。

下面是我测试使用的命令脚本，通过 `-i` 参数指定运行的测试次数：

```sh
/opt/oracle_jdk1.8.0_202/bin/java -jar SPECjvm2008.jar -ikv -i 15 compress
/opt/adopt_jdk8/bin/java -jar SPECjvm2008.jar -ikv -i 15 compress
/opt/bellsoft_jdk8u372/bin/java -jar SPECjvm2008.jar -ikv -i 15 compress
/opt/bisheng-jdk1.8.0_372/bin/java -jar SPECjvm2008.jar -ikv -i 15 compress
/opt/dragonwell-8.15.16/bin/java -jar SPECjvm2008.jar -ikv -i 15 compress
/opt/TencentKona-8.0.14-372/bin/java -jar SPECjvm2008.jar -ikv -i 15 compress
```

#### Oracle

```sh
Benchmark                     Iteration      Expected(ms)   Actual(ms)     Operations     ops/m
---------------------------------------------------------------------------------------------------

compress                      warmup         120000         120000         1348.58        674.29
compress                      iteration 1    240000         240000         2712.59        678.15
compress                      iteration 2    240000         240000         2709.13        677.28
compress                      iteration 3    240000         240000         2737.84        684.46
compress                      iteration 4    240000         240000         2705.39        676.35
compress                      iteration 5    240000         240000         2773.42        693.35
compress                      iteration 6    240000         240000         2668.66        667.16
compress                      iteration 7    240000         240000         2657.45        664.36
compress                      iteration 8    240000         240000         2643.21        660.80
compress                      iteration 9    240000         240000         2666.88        666.72
compress                      iteration 10   240000         240000         2668.32        667.08
compress                      iteration 11   240000         240000         2683.72        670.93
compress                      iteration 12   240000         240000         2686.89        671.72
compress                      iteration 13   240000         240000         2687.97        671.99
compress                      iteration 14   240000         240000         2698.49        674.62
compress                      iteration 15   240000         240000         2705.24        676.31
```

![Oracle_compress_results](https://img-blog.csdnimg.cn/d5b86cb0b744424abbf2f9cf90bcbc48.png)

#### Temurin

```sh
Benchmark                     Iteration      Expected(ms)   Actual(ms)     Operations     ops/m
---------------------------------------------------------------------------------------------------

compress                      warmup         120000         120000         1359.63        679.82
compress                      iteration 1    240000         240000         2715.53        678.88
compress                      iteration 2    240000         240000         2709.25        677.31
compress                      iteration 3    240000         240000         2704.85        676.21
compress                      iteration 4    240000         240000         2715.26        678.82
compress                      iteration 5    240000         240000         2709.50        677.38
compress                      iteration 6    240000         240000         2708.65        677.16
compress                      iteration 7    240000         240000         2718.06        679.51
compress                      iteration 8    240000         240000         2709.23        677.31
compress                      iteration 9    240000         240000         2792.29        698.07
compress                      iteration 10   240000         240000         2772.36        693.09
compress                      iteration 11   240000         240000         2792.81        698.20
compress                      iteration 12   240000         240000         2786.46        696.62
compress                      iteration 13   240000         240000         2790.96        697.74
compress                      iteration 14   240000         240000         2793.95        698.49
compress                      iteration 15   240000         240000         2795.06        698.76
```

![Temurin_compress_results](https://img-blog.csdnimg.cn/5c55830727c9472daf1a833989cf3818.png)

#### BellSoft

```sh
Benchmark                     Iteration      Expected(ms)   Actual(ms)     Operations     ops/m
---------------------------------------------------------------------------------------------------

compress                      warmup         120000         120000         1382.44        691.22
compress                      iteration 1    240000         240000         2737.99        684.50
compress                      iteration 2    240000         240000         2729.82        682.45
compress                      iteration 3    240000         240000         2724.39        681.10
compress                      iteration 4    240000         240000         2715.64        678.91
compress                      iteration 5    240000         240000         2719.60        679.90
compress                      iteration 6    240000         240000         2720.41        680.10
compress                      iteration 7    240000         240000         2730.70        682.67
compress                      iteration 8    240000         240000         2690.86        672.72
compress                      iteration 9    240000         240000         2764.42        691.10
compress                      iteration 10   240000         240000         2757.07        689.27
compress                      iteration 11   240000         240000         2774.10        693.53
compress                      iteration 12   240000         240000         2756.02        689.00
compress                      iteration 13   240000         240000         2764.45        691.11
compress                      iteration 14   240000         240000         2764.59        691.15
compress                      iteration 15   240000         240000         2764.30        691.07
```

![BellSoft_compress_results](https://img-blog.csdnimg.cn/82715f8b123842bf814fa7b3d090e33d.png)

#### Bisheng

```sh
Benchmark                     Iteration      Expected(ms)   Actual(ms)     Operations     ops/m
---------------------------------------------------------------------------------------------------

compress                      warmup         120000         120000         1310.83        655.42
compress                      iteration 1    240000         240000         2589.49        647.37
compress                      iteration 2    240000         240000         2622.27        655.57
compress                      iteration 3    240000         240000         2611.33        652.83
compress                      iteration 4    240000         240000         2605.32        651.33
compress                      iteration 5    240000         240000         2612.51        653.13
compress                      iteration 6    240000         240000         2649.15        662.29
compress                      iteration 7    240000         240000         2656.74        664.18
compress                      iteration 8    240000         240000         2653.27        663.32
compress                      iteration 9    240000         240000         2659.38        664.85
compress                      iteration 10   240000         240000         2657.91        664.48
compress                      iteration 11   240000         240000         2654.81        663.70
compress                      iteration 12   240000         240000         2653.45        663.36
compress                      iteration 13   240000         240000         2654.64        663.66
compress                      iteration 14   240000         240000         2656.29        664.07
compress                      iteration 15   240000         240000         2662.98        665.75
```

![Bisheng_compress_results](https://img-blog.csdnimg.cn/f0e7bf9e74664bbe8e4cfd7a1dbba8f5.png)

#### Dragonwell

```sh
Benchmark                     Iteration      Expected(ms)   Actual(ms)     Operations     ops/m
---------------------------------------------------------------------------------------------------

compress                      warmup         120000         120000         1350.02        675.01
compress                      iteration 1    240000         240000         2688.59        672.15
compress                      iteration 2    240000         240000         2692.88        673.22
compress                      iteration 3    240000         240000         2720.37        680.09
compress                      iteration 4    240000         240000         2712.36        678.09
compress                      iteration 5    240000         240000         2733.19        683.30
compress                      iteration 6    240000         240000         2769.88        692.47
compress                      iteration 7    240000         240000         2780.51        695.13
compress                      iteration 8    240000         240000         2785.72        696.43
compress                      iteration 9    240000         240000         2788.66        697.17
compress                      iteration 10   240000         240000         2788.07        697.02
compress                      iteration 11   240000         240000         2785.60        696.40
compress                      iteration 12   240000         240000         2786.39        696.60
compress                      iteration 13   240000         240000         2789.81        697.45
compress                      iteration 14   240000         240000         2790.98        697.74
compress                      iteration 15   240000         240000         2784.83        696.21
```

![Dragonwell_compress_results](https://img-blog.csdnimg.cn/ad023ae2f27d4dd4830812e86b558e58.png)

#### TencentKona

```bash
Benchmark                     Iteration      Expected(ms)   Actual(ms)     Operations     ops/m          
---------------------------------------------------------------------------------------------------

compress                      warmup         120000         120000         1365.93        682.97         
compress                      iteration 1    240000         240000         2664.85        666.21         
compress                      iteration 2    240000         240000         2702.75        675.69         
compress                      iteration 3    240000         240000         2706.60        676.65         
compress                      iteration 4    240000         240000         2709.98        677.50         
compress                      iteration 5    240000         240000         2736.24        684.06         
compress                      iteration 6    240000         240000         2762.78        690.70         
compress                      iteration 7    240000         240000         2817.31        704.33         
compress                      iteration 8    240000         240000         2834.28        708.57         
compress                      iteration 9    240000         240000         2833.27        708.32         
compress                      iteration 10   240000         240000         2826.15        706.54         
compress                      iteration 11   240000         240000         2838.10        709.52         
compress                      iteration 12   240000         240000         2841.51        710.38         
compress                      iteration 13   240000         240000         2835.76        708.94         
compress                      iteration 14   240000         240000         2774.24        693.56         
compress                      iteration 15   240000         240000         2776.13        694.03     
```

![TencentKona_compress_results](https://img-blog.csdnimg.cn/2c8059e627914860ae929bf047b7ac94.png)

---
方差齐性检验：
![方差齐性检验](https://img-blog.csdnimg.cn/659197f11e264d95b48052d0fba0660f.png)
如果方差齐性检验通过，则执行student's t test，否则执行Welch's t-test，标\*则认为存在显著性差异
![显著性差异](https://img-blog.csdnimg.cn/89f4c4e11565454fadb298bd623cc5e4.png)
这个结果显示标\*的组存在显著性差异。

我认为两次测量结果相差比较大，在测量的方法上还存在欠缺（WSL难以排除其他Windows进程的干扰）。两次结果相同的地方似乎只有Oracle jdk8 202版本这一组的数据相较其他组存在显著差异。

---


> Why is there run to run performance variation?   
> What contributes to run-to-run variation?  
> How do we validate the factors contributing to run-to-run variation?   

为了解答这个问题，我们首先考虑一下有哪些因素是可能导致数值上的差异

1. System load: 系统上运行的其他进程或应用程序可能会占用CPU和内存资源，从而产生不同运行次数之间的差异
2. Resource contention: 多个线程或进程可能会竞争对内存、磁盘I/O或网络带宽等资源的访问，争用和延迟会产生差异
3. Garbage collection: GC会影响性能，如果垃圾收集运行的频率和持续时间在不同的测试运行中会有所不同，那么就会产生差异
4. Randomness in benchmark: 如果 benchmark 本身存在随机性，那么也会产生差异
5. Hardware variations: 比如发热等因素可能导致硬件的性能变化，进而产生差异（另外硬件也存在较低的随机性和错误的可能性）

我运行的是 `compress` 这个测试项，来看看代码吧。

```java
// src/spec/benchmarks/compress/Harness.java
    public static final String[] FILES_NAMES = new String[] {
        "resources/compress/input/202.tar",
        "resources/compress/input/205.tar",
        "resources/compress/input/208.tar",
        "resources/compress/input/209.tar",
        "resources/compress/input/210.tar",
        "resources/compress/input/211.tar",
        "resources/compress/input/213x.tar",
        "resources/compress/input/228.tar",
        "resources/compress/input/239.tar",
        "resources/compress/input/misc.tar"};
    
    public static final int FILES_NUMBER = FILES_NAMES.length;
    public static final int LOOP_COUNT = 2;
    public static Source[] SOURCES;
    public static byte[][] COMPRESS_BUFFERS;
    public static byte[][] DECOMPRESS_BUFFERS;
    public static Compress CB;
    public void runCompress(int btid) {
        spec.harness.Context.getOut().println("Loop count = " + LOOP_COUNT);
        for (int i = 0; i < LOOP_COUNT; i++) {
            for (int j = 0; j < FILES_NUMBER; j++) {
                Source source = SOURCES[j];
                OutputBuffer comprBuffer, decomprBufer;
                comprBuffer = CB.performAction(source.getBuffer(),
                        source.getLength(),
                        CB.COMPRESS,
                        COMPRESS_BUFFERS[btid - 1]);
                decomprBufer = CB.performAction(COMPRESS_BUFFERS[btid - 1],
                        comprBuffer.getLength(),
                        CB.UNCOMPRESS,
                        DECOMPRESS_BUFFERS[btid - 1]);
                Context.getOut().print(source.getLength() + " " + source.getCRC() + " ");
                Context.getOut().print(comprBuffer.getLength() + comprBuffer.getCRC() + " ");
                Context.getOut().println(decomprBufer.getLength() + " " + decomprBufer.getCRC());
            }
        }
    }
```

可以看到它对一系列文件依次运行了压缩和解压缩文件的操作，压缩和解压缩的实现细节在`src/spec/benchmarks/compress/Compress.java`里，代码太长了就不贴了。

我们主要看`compress()`和`decompress()`这两个函数

`decompress()`通过对读取到的编码进行反向解码，依次将解码结果存入栈中。在栈中的解码结果存储完毕后，再按照正序依次取出并输出，从而实现解压缩。大致流程如下：

1. 检查输入数据是否为压缩格式，如果不是则输出错误信息；
2. 读取压缩数据文件中的设置参数，包括：压缩块大小、编码字符数量等；
3. 初始化解压缩所需的数据结构和变量，包括：表格、栈、偏移量等；
4. 在读取到每个编码时，进行解码操作并将解码结果按顺序放入栈中；
5. 将栈中存储的编码结果按正序依次输出，并更新表格中的编码映射关系；
6. 重复步骤4~5直到全部编码处理完毕。

它使用了一些辅助变量和函数，比如`getCode()`获取下一个编码、`deStack`栈用于存储解码结果、`tabPrefix`和`tabSuffix`表格用于存储编码和解码映射关系等。

`compress()`实现了一个压缩过程，主要流程如下：
1. 初始化哈希表中的设置参数，如哈希表大小、最大编码位数等；
2. 读取输入文件中的第一个字节作为初始字符，并将其存入哈希表中；
3. 从输入文件中依次读取每个字符，计算其哈希值，并将其与哈希表中存储的编码进行比较；
4. 如果在哈希表中找到了对应的编码，则说明当前字符已经存在于哈希表中，直接继续处理下一个字符；
5. 否则，将当前字符的编码和前一个字符的编码合并作为新的编码，并将其输出到输出文件中；
6. 如果哈希表中还有空闲的槽位，将新的编码加入哈希表中，并更新哈希表中对应的编码映射关系；
7. 如果哈希表已满或者已经处理了一定数量的字符，则需要执行块压缩（`clBlock()`函数），将当前哈希表中的所有编码输出到输出文件中，并重新初始化哈希表；
8. 循环执行步骤3~7，直到输入文件中的所有字符都被处理完毕。  

`compress()`中包含一些涉及随机性质的操作或函数，例如`hshift`变量的计算、使用异或运算进行哈希等。  
这些随机性质主要是用于减小哈希碰撞的概率，提高编码压缩效率。
`compress()`中并未使用任何具有真正意义上的随机操作或函数，因此仍然可以认为`compress()`是确定性的。

用异或实现的哈希是可重复的，并不会带来运行之间的差异。所以我认为对于compress这个测试项目来说，benchmark 本身不存在可以影响分数(aka操作数每分钟)的随机性，第四点猜想可以排除。

那么是否存在GC造成的随机影响呢？这一点我不太确定，不过`props/specjvm.properties`中存在配置项用于在benchmark之前和iteration之间强制开启GC。

垃圾收集运行的频率和持续时间在不同的测试运行中会有所不同吗？我猜测对于不同的jdk，也许存在不同的策略，但对于同一jdk的多次运行结果应该不存在不同。（可能应该开启`specjvm.iteration.systemgc`来减少影响？）另外，我们还可以通过一些JVM的配置项来控制GC（但是要加`-pja`参数来解析jvm arguments）

```sh
# specjvm.benchmark.systemgc=!
# Specify if a GC should be forced before each benchmark.
# Valid values: true, false
# Default value: false
# Permitted for compliant run: false
# Permitted for Lagom run: false

# specjvm.iteration.systemgc=false=,false=
# Specify if a GC should be forced between each iteration.
# Valid values: true, false
# Default value: false
# Permitted for compliant run: false
# Permitted for Lagom run: false
```



> What are the pros and cons of using arithmetic mean versus geometric mean in summarizing scores? 

Pros of arithmetic mean:

简单直接，易于理解

Cons of arithmetic mean:

1. 异常值影响大，导致偏差
2. 它假设数据是正态分布的

Pros of geometric mean:

1. 对异常值不敏感，更鲁棒
2. 它可以反映数据的乘法性质

Cons of geometric mean:

1. 只能处理正整数
2. 不便于大众理解
3. 低估极端值的影响

Conclusion:

- 当处理的数据中包括百分比、利润率、增长率等呈现比例关系的数据时，通常使用几何平均更为合适。
- 当数据服从正态分布并且不存在极值时，算术平均是合适的。

> Why does SPECjvm2008 use geometric mean?

几何平均值对异常值不太敏感，提供了更准确的总体性能表示。


## 一些其他的 Q&A

### JVM Version

> Q: Is there a command line option to dump the JVM version in the output?

`-v`选项可以 `Print verbose info (harness only).`

可以输出 JVM version （当然也输出了很多别的信息）

我怀疑这个不算正确答案，但是我看了好几遍 User's Guide 附录A `SPECjvm2008 command line options` 都没找到单独输出这个的。

不过我在代码里找到了这个：

```java
package spec.harness;

public class VMVersionTest {
    static String[] properties = {"java.version",
    "java.vm.version",
    "java.home"};
    
    public static String getVersionInfo() {
        String result = "";
        for(int i = 0; i < properties.length; i ++) {
            result += properties[i] + ":" + System.getProperty(properties[i]) + "\n";
        }
        return result;
    }
    public static void main(String[] args) {
        System.out.print(getVersionInfo());
    }
}
```

### What is the performance metric

> Q: 
> What is the performance metric? What are the units of measurement?
> How is it defined?
> What factors affect scores? Why do some get higher scores, but others get lower scores?

我们可以在User's Guide里找到答案

> 6 Throughput Measurement  
> In a given run, each SPECjvm2008 sub-benchmark produces a result in ops/min (operations per minute) that reflects the rate at which the system was able to complete invocations of the workload of that sub-benchmark. At the conclusion of a run, SPECjvm2008 computes a single quantity intended to reflect the overall performance of the system on all the sub-benchmarks executed during the run. The basic method used to compute the combined result is to compute a geometric mean. However, because it is desired to reflect performance on various application areas more or less equally, the computation done is a little more complex than a straight geometric mean of the sub-benchmark results.  
> 
> In order to include multiple sub-benchmarks that represent the same general application area while still treating various application areas equally, an intermediate result is computed for certain groups of the sub-benchmarks before they are combined into the overall throughput result. In particular, for these groups of sub-benchmarks  
> 
> COMPILER: compiler.compiler, compiler.sunflow  
> 
> CRYPTO: crypto.aes, crypto.rsa, crypto.signverify  
> 
> SCIMARK: scimark.fft.large, scimark.lu.large, scimark.sor.large, scimark.sparse.large, scimark.fft.small, scimark.lu.small, scimark.sor.small, scimark.sparse.small, scimark.monte_carlo  
> 
> STARTUP: {all sub-benchmarks having names beginning with startup. } See Appendix A for the complete list.  
> 
> XML: xml.transform, xml.validation  
> 
> the geometric mean of sub-benchmark results in each group is computed. The overall throughput result is then computed as the geometric mean of these group results and the results from the other sub-benchmarks.  
> 
> While throughput results obtained from runs that execute only selected sub-benchmarks may be interesting and useful for research purposes, only the overall throughput results from runs that execute all the sub-benchmarks (and satify several other conditions as well) are deemed to represent the performance of the system on SPECjvm2008 per se. The conditions under which an overall throughput result represents a SPECjvm2008 metric is discussed in detail in the "Run and Reporting Rules".  

影响因素见上文。



## 一些坑

- 安装过程中卡住：如上文所述，需要安装依赖
- **Java8 不支持，卡住**：运行到sunflow时卡住，官方文档已经指出Java8不支持4个测试项
- 一部分测试项存在文件读写，而我手上的电脑存在对一部分格式的文件落地加密的机制，并可能由此引发了错误（尚不确定），为了定位和确认这个问题我运行了60多遍SPECjvm2008。  
    derby
![报错](https://img-blog.csdnimg.cn/4f98377e73d84ba88b9a232160b4972f.png)
scimark
![报错](https://img-blog.csdnimg.cn/988bcaeed1864e8cbcbde4c6450b0346.png)
![报错](https://img-blog.csdnimg.cn/ba16f2fac3274ea9a2d0d478124cf61d.png)
![报错](https://img-blog.csdnimg.cn/cb5837180b0b40f89c03db2bbe4fe4c3.png)

## Reference

1. SPECjvm2008 User's Guide <https://www.spec.org/jvm2008/docs/UserGuide.html#SPECjvm2008Parameters>
2. 特别鸣谢：OpenAI chatGPT <https://openai.com/chatgpt>

使用到的包:

1. OracleJDK <https://repo.huaweicloud.com/java/jdk/8u202-b08/jdk-8u202-linux-x64.tar.gz>
2. Adoptium Eclipse Temurin <https://mirrors.tuna.tsinghua.edu.cn/help/adoptium/>
3. Liberica JDK <https://bell-sw.com/pages/downloads/>
4. Dragonwell JDK <https://github.com/dragonwell-project/dragonwell8/releases/download/dragonwell-extended-8.15.16_jdk8u372-ga/Alibaba_Dragonwell_Extended_8.15.16_x64_linux.tar.gz>
5. Tencent JDK <https://github.com/Tencent/TencentKona-8/releases/download/8.0.14-GA/TencentKona8.0.14.b1_jdk_linux-x86_64_8u372.tar.gz>
6. Huawei JDK <https://gitee.com/link?target=https%3A%2F%2Fmirrors.huaweicloud.com%2Fkunpeng%2Farchive%2Fcompiler%2Fbisheng_jdk%2Fbisheng-jdk-8u372-linux-x64.tar.gz>
7. SPECjvm2008 <https://www.spec.org/jvm2008/>

