FROM centos:centos7.3.1611
LABEL maintainer="Song Yuning <songyuning@inspur.com>"
WORKDIR /bigdata/ambari-2.7.4-sourcecode

# 环境变量
ENV JAVA_HOME /usr/lib/jdk-1.8.0-232 
ENV CLASSPATH ${JAVA_HOME}/jre/lib:${JAVA_HOME}/lib
ENV NODE_HOME=/opt/node-v4.5.0
ENV _JAVA_OPTIONS="-Xmx2048m -XX:MaxPermSize=512m -Djava.awt.headless=true"

ENV TZ Asia/Shanghai

ENV PATH ${JAVA_HOME}/bin:$PATH:/opt/apache-maven-3.5.4/bin:/opt/apache-ant-1.10.7/bin:/opt/node-v4.5.0/bin:opt/phantomjs-2.1.1-linux-x86_64/bin

ENV HD1_REPO_URL http://10.221.129.22/InspurHD1.0
ENV AMBARI_VERSION 2.7.4.0.0

# 增加源repo文件
# ADD resources/Cenos-inspur.repo /etc/yum/repos.d/Centos-inspur.repo
ADD resources/repo/Centos-7-ali.repo /etc/yum/repos.d/Centos-7-ali.repo

# 更新/安装必要软件
RUN set -x \
    && yum clean all \
    && yum makecache \
    && yum update  -y \
    && yum install -y wget \
    && cd /bigdata/ambari-2.7.4-sourcecode \
    # && wget http://mirror.bit.edu.cn/centos/7.7.1908/os/x86_64/Packages/net-tools-2.0-0.25.20131004git.el7.x86_64.rpm \
    && yum install -y vim curl net-tools telnet procps gzip python2.7 python-pip python-dev git rpm-build npm gcc-c++ exit 0

# 安装 Open JDK
RUN set -x \
  && wget ${HD1_REPO_URL}/jdk/jdk-1.8.0-232.tar.gz  -O /tmp/jdk-1.8.0-232.tar.gz \
  && tar -zxvf /tmp/jdk-1.8.0-232.tar.gz -C /usr/lib/ \
  && chmod -R 755 ${JAVA_HOME} \
  && java -version \
  && mkdir -p /usr/share/java \
  && cd /usr/share/java \
  && wget http://10.221.129.22/InspurHD1.0/jdk/mysql-connector-java-5.1.48.jar

#安装 Maven
RUN set -x \
  && cd /opt \
  && wget http://mirrors.hust.edu.cn/apache/maven/maven-3/3.5.4/binaries/apache-maven-3.5.4-bin.tar.gz \
  && tar -zxvf apache-maven-3.5.4-bin.tar.gz \
  && rm -f /opt/apache-maven-3.5.4/conf/settings.xml

# 添加 maven 配置文件
ADD resources/settings.xml /opt/apache-maven-3.5.4/conf/settings.xml
RUN mvn -version

# 安装 Ant
RUN set -x \
  && cd /opt \
  && wget http://mirrors.hust.edu.cn/apache/ant/binaries/apache-ant-1.10.7-bin.tar.gz \
  && tar -zxvf apache-ant-1.10.7-bin.tar.gz \
  && ant -version 

# 下载项目源码并切换到分支
RUN set -x \
  && cd /bigdata \
  && git clone http://songyuning:Syuning1993@git.inspur.com/Insight-HD/insight-hd/ambari-2.7.4-sourcecode.git \
  && cd ambari-2.7.4-sourcecode \
  && git branch -a \
  && git checkout -b bs remotes/origin/bs \
  && git pull \
  && git branch

# 安装 NodeJS
RUN set -x \
&& cd resources/maven-repo/com/github/eirslett/node/4.5.0/node-4.5.0-linux-x64.tar.gz \
&& tar -zxvf node-v4.5.0-linux-x64.tar.gz \
&& mv node-v4.5.0-linux-x64 /opt/node-v4.5.0 \
&& node -v \
&& npm config set registry https://registry.npm.taobao.org/
# npm install --registry=https://registry.npm.taobao.org 一次性淘宝源安装
# && npm install -g bower \
# && npm install -g gulp \
# && npm install -g brunch
# && brunch -v

# 安装 PhantomJS
RUN set -x \
  && tar -jxvf bigdata/maven-repo/phantomjs-2.1.1-linux-x86_64.tar.bz2 \
  && mv bigdata/maven-repo/phantomjs-2.1.1-linux-x86_64 /opt

# Maven设置版本准备编译
RUN set -x \
  && cd /bigdata/ambari-2.7.4-sourcecode \
  && mvn versions:set -DnewVersion=2.7.4.0.0 \
  && pushd ambari-metrics \
  && mvn versions:set -DnewVersion=2.7.4.0.0 \
  && popd

########################################################## 构建镜像 & 运行容器 #################################################################
# 构建docker镜像，--rm删除之前所有缓存，-t给生成的镜像打tag
# docker build --rm -t docker-images/ambari-cmp-env:2.7.4.0.0 .

# 查看当前所有镜像
# docker images 

# 登录、将镜像推至镜像仓库、从镜像仓库拉取镜像
# docker login
# docker push docker-images/ambari-cmp-env:2.7.4.0.0
# docker pull docker-images/ambari-cmp-env:2.7.4.0.0

# 本地导出镜像为tar
# docker save -o latest.tar docker-images/ambari-cmp-env:2.7.4.0.0

# 本地导出容器为tar(重复执行会替换当前重名tar)
# docker export --output="exampleimage.tar" 容器ID
# docker export 容器ID > exampleimage.tar

# 注：导出容器时将忽略已挂载的卷，因此直接导出镜像和该镜像执行的容器可能会导出不同的tar文件

# 本地导入tar压缩包镜像
# docker import /path/to/exampleimage.tar
# 之后docker images查看当前镜像，新生成的镜像就在列表第一个

# 以该镜像id运行一个容器，将宿主机的maven-repo挂载到镜像
# docker run -i -t -v  /Users/songyuning/workspace/Codes/maven-repo:/bigdata/maven-repo docker-images/ambari-cmp-env:2.7.4.0.0 /bin/bash 

# 查看当前容器
# docker ps

# 运行容器
# docker exec -it cf25e294d99b bash 

# 停止容器
# docker stop cf25e294d99b

# 删除镜像
# docker rmi -f c6f5d0e1b4b3 
########################################################## 构建镜像 & 运行容器 #################################################################


############################################################ 编译 ###################################################################
# 编译ambari
# mvn -B -X install package rpm:rpm -DnewVersion=2.7.4.0.0 -DskipTests -Dbuild-rpm -Dpython.ver="python >= 2.6" -Drat.skip=true

# 单独编译ambari-metrics
# cd ambari-metrics
# mvn clean package -Dbuild-rpm -DskipTests

# 编译过程中出错被打断时日志如下：
# [ERROR] Failed to execute goal com.github.eirslett:frontend-maven-plugin:1.4:install-node-and-yarn (install node and yarn) on project ambari-web: Could not extract the Node archive: Could not extract archive: '/bigdata/maven-repo/com/github/eirslett/node/4.5.0/node-4.5.0-linux-x64.tar.gz': EOFException -> [Help 1] org.apache.maven.lifecycle.LifecycleExecutionException: Failed to execute goal com.github.eirslett:frontend-maven-plugin:1.4:install-node-and-yarn (install node and yarn) on project ambari-web: Could not extract the Node archive: Could not extract archive: '/bigdata/maven-repo/com/github/eirslett/node/4.5.0/node-4.5.0-linux-x64.tar.gz'
# ...
# [ERROR] For more information about the errors and possible solutions, please read the following articles:
# [ERROR] [Help 1] http://cwiki.apache.org/confluence/display/MAVEN/MojoFailureException
# [ERROR] 
# [ERROR] After correcting the problems, you can resume the build with the command
# [ERROR]   mvn <goals> -rf :ambari-web

# 手动解决后使用此命令继续编译：mvn com.github.eirslett:frontend-maven-plugin:1.4:install-node-and-yarn -rf :ambari-web

# [root@57a52c01dd5e ambari-2.7.4-sourcecode]# mvn com.github.eirslett:frontend-maven-plugin:1.4:install-node-and-yarn -rf :ambari-web
# Picked up _JAVA_OPTIONS: -Xmx2048m -XX:MaxPermSize=512m -Djava.awt.headless=true
# OpenJDK 64-Bit Server VM warning: ignoring option MaxPermSize=512m; support was removed in 8.0
# [INFO] Scanning for projects...

# mvn com.github.eirslett:frontend-maven-plugin:1.4:install-node-and-yarn -rf :ambari-views

# 在docker容器和宿主机之间复制文件
# docker cp 1e321726a150:/bigdata/ambari-2.7.4-sourcecode/resources/maven-repo /Users/songyuning/workspace/Codes/ambari-2.7.4-sourcecode/resources/maven-repo
# docker cp /Users/songyuning/workspace/Codes/ambari-2.7.4-sourcecode/resources/maven-reepo 1e321726a150:/bigdata/ambari-2.7.4-sourcecode/resources/maven-repo

# rpm存放路径： 
# Ambari Server - AMBARI_DIR/ambari-server/target/rpm/ambari-server/RPMS/noarch
# Ambari Agent - AMBARI_DIR/ambari-agent/target/rpm/ambari-agent/RPMS/x86_64
############################################################ 编译 ###################################################################
