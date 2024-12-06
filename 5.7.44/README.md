# mysql-5.7.44

1、采用自编译MySQL的方式制作5.7.44的镜像，这样就能支持amd64和arm64架构的机器

2、修改了MySQL源码包里的boost的下载地址，是为了解决下载速度慢的问题。mysql-5.7.44/cmake/boost.cmake
```
SET(BOOST_DOWNLOAD_URL
  "https://archives.boost.io/release/1.59.0/source/${BOOST_TARBALL}"
  )
```

3、构建和执行
```
docker build -t menzai/mysql-5.7.44-alpine:v2 .

docker run -p 3306:3306 -d -e MYSQL_ROOT_PASSWORD=a123456 --name mysql5.7.44 -it menzai/mysql-5.7.44-alpine:v2
```

4、官方Dockerfile文件及自启动文件https://github.com/docker-library/mysql/commit/3e959c224b965b0dd92a59a1dedeb7c34a24f550