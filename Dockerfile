FROM openresty/openresty:1.19.3.1-1-centos AS last-stage

MAINTAINER "shenshuo<191715030@qq.com>"

## 设置编码
ENV LANG en_US.UTF-8
# 同步时间
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

COPY . /usr/local/openresty/nginx/
COPY ./conf/app.example.json /usr/local/openresty/nginx/conf/app.json

WORKDIR /usr/local/openresty/nginx/
VOLUME /usr/local/openresty/nginx/logs/

EXPOSE 8888 11000

CMD ["/usr/bin/openresty", "-g", "daemon off;"]

STOPSIGNAL SIGQUIT

# docker build . -t tianmen2_image
