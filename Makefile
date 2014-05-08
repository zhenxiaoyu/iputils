#
# Configuration
#

# CC
# 指定gcc程序
CC=gcc
# Path to parent kernel include files directory
# 父路径内核包含的文件目录
LIBC_INCLUDE=/usr/include
# Libraries
ADDLIB=
# Linker flags
# 链接器标志
# -Wl，-Bstatic告诉链接器使用-Bstatic选项，该选项是告诉链接器，对接下来的-l选项使用静态链接
# -Wl,-Bdynamic就是告诉链接器对接下来的-l选项使用动态链接
LDFLAG_STATIC=-Wl,-Bstatic
LDFLAG_DYNAMIC=-Wl,-Bdynamic
# 指定加载库
#CAP函数库
LDFLAG_CAP=-lcap
#TLS加密库
LDFLAG_GNUTLS=-lgnutls-openssl
# CRYPTO加密解密库
LDFLAG_CRYPTO=-lcrypto
# IDN恒等函数库
LDFLAG_IDN=-lidn
# RESOLV函数库
LDFLAG_RESOLV=-lresolv
# SYSFS接口函数库
LDFLAG_SYSFS=-lsysfs

#
# Options
#
# 变量定义，设置开关
# Capability support (with libcap) [yes|static|no]
#CAP函数库支持
# [yes|static|no] 表示 是，静态 ，否
USE_CAP=yes
# sysfs support (with libsysfs - deprecated) [no|yes|static]
#SYSFS函数库支持
USE_SYSFS=no
# IDN support (experimental) [no|yes|static]
#IDN函数库支持
USE_IDN=no

# Do not use getifaddrs [no|yes|static]
# 不要使用getifaddrs
WITHOUT_IFADDRS=no
# arping default device (e.g. eth0) []
# arp默认设备
ARPING_DEFAULT_DEVICE=

# GNU TLS library for ping6 [yes|no|static]
# 默认GNU TLS库ping6的状态
USE_GNUTLS=yes
# Crypto library for ping6 [shared|static]
# 默认加密解密库ping6的状态 
# shared 共享
USE_CRYPTO=shared
# Resolv library for ping6 [yes|static]
# 默认RESOLV库ping6状态
USE_RESOLV=yes
# ping6 source routing (deprecated by RFC5095) [no|yes|RFC3542]
# ping6源路由
ENABLE_PING6_RTHDR=no

# rdisc server (-r option) support [no|yes]
# rdisc服务器支持（默认不支持-r选项）
# rdisc是路由器发现守护程序
ENABLE_RDISC_SERVER=no

# -------------------------------------
# What a pity, all new gccs are buggy and -Werror does not work. Sigh.
# CCOPT=-fno-strict-aliasing -Wstrict-prototypes -Wall -Werror -g
#-Wstrict-prototypes: 如果函数的声明或定义没有指出参数类型，编译器就发出警告
# gcc变量定义
CCOPT=-fno-strict-aliasing -Wstrict-prototypes -Wall -g
CCOPTOPT=-O3
GLIBCFIX=-D_GNU_SOURCE
DEFINES=
LDLIB=

FUNC_LIB = $(if $(filter static,$(1)),$(LDFLAG_STATIC) $(2) $(LDFLAG_DYNAMIC),$(2))

# USE_GNUTLS: DEF_GNUTLS, LIB_GNUTLS
# USE_CRYPTO: LIB_CRYPTO
# if条件判断CRYPTO函数库中的函数是否重复
ifneq ($(USE_GNUTLS),no)
	LIB_CRYPTO = $(call FUNC_LIB,$(USE_GNUTLS),$(LDFLAG_GNUTLS))
	DEF_CRYPTO = -DUSE_GNUTLS
else
	LIB_CRYPTO = $(call FUNC_LIB,$(USE_CRYPTO),$(LDFLAG_CRYPTO))
endif

# USE_RESOLV: LIB_RESOLV
# RESOLV函数库中函数是否重复
LIB_RESOLV = $(call FUNC_LIB,$(USE_RESOLV),$(LDFLAG_RESOLV))

# USE_CAP:  DEF_CAP, LIB_CAP
# CAP函数库中函数是否重复
ifneq ($(USE_CAP),no)
	DEF_CAP = -DCAPABILITIES
	LIB_CAP = $(call FUNC_LIB,$(USE_CAP),$(LDFLAG_CAP))
endif

# USE_SYSFS: DEF_SYSFS, LIB_SYSFS
# SYSFS函数库中函数是否重复
ifneq ($(USE_SYSFS),no)
	DEF_SYSFS = -DUSE_SYSFS
	LIB_SYSFS = $(call FUNC_LIB,$(USE_SYSFS),$(LDFLAG_SYSFS))
endif

# USE_IDN: DEF_IDN, LIB_IDN
# IDN函数库中函数是否重复
ifneq ($(USE_IDN),no)
	DEF_IDN = -DUSE_IDN
	LIB_IDN = $(call FUNC_LIB,$(USE_IDN),$(LDFLAG_IDN))
endif

# WITHOUT_IFADDRS: DEF_WITHOUT_IFADDRS
ifneq ($(WITHOUT_IFADDRS),no)
	DEF_WITHOUT_IFADDRS = -DWITHOUT_IFADDRS
endif

# ENABLE_RDISC_SERVER: DEF_ENABLE_RDISC_SERVER
ifneq ($(ENABLE_RDISC_SERVER),no)
	DEF_ENABLE_RDISC_SERVER = -DRDISC_SERVER
endif

# ENABLE_PING6_RTHDR: DEF_ENABLE_PING6_RTHDR
ifneq ($(ENABLE_PING6_RTHDR),no)
	DEF_ENABLE_PING6_RTHDR = -DPING6_ENABLE_RTHDR
ifeq ($(ENABLE_PING6_RTHDR),RFC3542)
	DEF_ENABLE_PING6_RTHDR += -DPINR6_ENABLE_RTHDR_RFC3542
endif
endif

# -------------------------------------
IPV4_TARGETS=tracepath ping clockdiff rdisc arping tftpd rarpd
IPV6_TARGETS=tracepath6 traceroute6 ping6
TARGETS=$(IPV4_TARGETS) $(IPV6_TARGETS)

CFLAGS=$(CCOPTOPT) $(CCOPT) $(GLIBCFIX) $(DEFINES)
LDLIBS=$(LDLIB) $(ADDLIB)

UNAME_N:=$(shell uname -n)
LASTTAG:=$(shell git describe HEAD | sed -e 's/-.*//')
TODAY=$(shell date +%Y/%m/%d)
DATE=$(shell date --date $(TODAY) +%Y%m%d)
TAG:=$(shell date --date=$(TODAY) +s%Y%m%d)


# -------------------------------------
#容错处理
# .PHONY修饰的目标只有规则没有依赖
.PHONY: all ninfod clean distclean man html check-kernel modules snapshot

all: $(TARGETS)

%.s: %.c
	$(COMPILE.c) $< $(DEF_$(patsubst %.o,%,$@)) -S -o $@
%.o: %.c
	$(COMPILE.c) $< $(DEF_$(patsubst %.o,%,$@)) -o $@
$(TARGETS): %: %.o
	$(LINK.o) $^ $(LIB_$@) $(LDLIBS) -o $@

#
# COMPILE.c=$(CC) $(CFLAGS) $(CPPFLAGS) -c
# $< 依赖目标中的第一个目标名字 
# $@ 表示目标
# $^ 所有的依赖目标的集合 
# 在$(patsubst %.o,%,$@ )中，patsubst把目标中的变量符合后缀是.o的全部删除,  DEF_ping
# LINK.o把.o文件链接在一起的命令行,缺省值是$(CC) $(LDFLAGS) $(TARGET_ARCH)
#
#以ping为例，翻译为：
# gcc -O3 -fno-strict-aliasing -Wstrict-prototypes -Wall -g -D_GNU_SOURCE    -c ping.c -DCAPABILITIES   -o ping.o
#gcc   ping.o ping_common.o -lcap    -o ping

# $(patsubst %.o,%,$@) 的意思是把指定filename.o文件变为filename
# patsubst函数：3个参数。功能是将第三个参数中的每一项（由空格分隔）符合第一个参数描述的部分替换成第二个参数制定的值



# -------------------------------------
# arping
# 使用arping向目的主机发送ARP报文，通过目的主机的IP获得该主机的硬件地址
# 通过几个库函数
DEF_arping = $(DEF_SYSFS) $(DEF_CAP) $(DEF_IDN) $(DEF_WITHOUT_IFADDRS)
LIB_arping = $(LIB_SYSFS) $(LIB_CAP) $(LIB_IDN)

ifneq ($(ARPING_DEFAULT_DEVICE),)
DEF_arping += -DDEFAULT_DEVICE=\"$(ARPING_DEFAULT_DEVICE)\"
endif

# clockdiff
#使用clockdiff测算目的主机和本地主机的系统时间差
DEF_clockdiff = $(DEF_CAP)
LIB_clockdiff = $(LIB_CAP)

# ping / ping6
# ping可以测试计算机名和计算机的ip地址，验证与远程计算机的连接
# ping程序由ping.c ping6.cping_common.c ping.h 文件构成
DEF_ping_common = $(DEF_CAP) $(DEF_IDN)
DEF_ping  = $(DEF_CAP) $(DEF_IDN) $(DEF_WITHOUT_IFADDRS)
LIB_ping  = $(LIB_CAP) $(LIB_IDN)
DEF_ping6 = $(DEF_CAP) $(DEF_IDN) $(DEF_WITHOUT_IFADDRS) $(DEF_ENABLE_PING6_RTHDR) $(DEF_CRYPTO)
LIB_ping6 = $(LIB_CAP) $(LIB_IDN) $(LIB_RESOLV) $(LIB_CRYPTO)

ping: ping_common.o
ping6: ping_common.o
ping.o ping_common.o: ping_common.h
ping6.o: ping_common.h in6_flowlabel.h

# rarpd
# rarpd是逆地址解析协议的服务端程序。rarpd程序由rarpd.c文件构成
DEF_rarpd =
LIB_rarpd =

# rdisc
# rdisc是路由器发现守护程序。rdisc程序由rdisc.c文件构成。
DEF_rdisc = $(DEF_ENABLE_RDISC_SERVER)
LIB_rdisc =

# tracepath
# tracepath测试IP数据报文从源主机传到目的主机经过的路由
DEF_tracepath = $(DEF_IDN)
LIB_tracepath = $(LIB_IDN)

# tracepath6
DEF_tracepath6 = $(DEF_IDN)
LIB_tracepath6 =

# traceroute6
DEF_traceroute6 = $(DEF_CAP) $(DEF_IDN)
LIB_traceroute6 = $(LIB_CAP) $(LIB_IDN)

# tftpd
# tftpd是简单文件传送协议TFTP的服务端程序
DEF_tftpd =
DEF_tftpsubs =
LIB_tftpd =

tftpd: tftpsubs.o
tftpd.o tftpsubs.o: tftp.h

# -------------------------------------
# ninfod
ninfod:
	@set -e; \ # 如果命令带非零值返回,立即退出
		if [ ! -f ninfod/Makefile ]; then \ # 当file存在并且是正规文件时返回真
			cd ninfod; \ # 返回指定目录
			./configure; \
			cd ..; \
		fi; \ # if语句的结尾
		$(MAKE) -C ninfod

# -------------------------------------
# modules / check-kernel are only for ancient kernels; obsolete
check-kernel:
ifeq ($(KERNEL_INCLUDE),)
	@echo "Please, set correct KERNEL_INCLUDE"; false #显示
else
	@set -e; \
	if [ ! -r $(KERNEL_INCLUDE)/linux/autoconf.h ]; then \
		echo "Please, set correct KERNEL_INCLUDE"; false; fi
endif

modules: check-kernel
	$(MAKE) KERNEL_INCLUDE=$(KERNEL_INCLUDE) -C Modules

# -------------------------------------
man:
	$(MAKE) -C doc man

html:
	$(MAKE) -C doc html

# clean 删除已生成的目标文件
clean:
	@rm -f *.o $(TARGETS)
	@$(MAKE) -C Modules clean
	@$(MAKE) -C doc clean
	@set -e; \
		if [ -f ninfod/Makefile ]; then \
			$(MAKE) -C ninfod clean; \
		fi

distclean: clean
	@set -e; \
		if [ -f ninfod/Makefile ]; then \
			$(MAKE) -C ninfod distclean; \
		fi

# -------------------------------------
snapshot:
	@if [ x"$(UNAME_N)" != x"pleiades" ]; then echo "Not authorized to advance snapshot"; exit 1; fi
	@echo "[$(TAG)]" > RELNOTES.NEW
	@echo >>RELNOTES.NEW
	@git log --no-merges $(LASTTAG).. | git shortlog >> RELNOTES.NEW
	@echo >> RELNOTES.NEW
	@cat RELNOTES >> RELNOTES.NEW
	@mv RELNOTES.NEW RELNOTES
	@sed -e "s/^%define ssdate .*/%define ssdate $(DATE)/" iputils.spec > iputils.spec.tmp
	@mv iputils.spec.tmp iputils.spec
	@echo "static char SNAPSHOT[] = \"$(TAG)\";" > SNAPSHOT.h
	@$(MAKE) -C doc snapshot
	@$(MAKE) man
	@git commit -a -m "iputils-$(TAG)"
	@git tag -s -m "iputils-$(TAG)" $(TAG)
	@git archive --format=tar --prefix=iputils-$(TAG)/ $(TAG) | bzip2 -9 > ../iputils-$(TAG).tar.bz2

