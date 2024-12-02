# mysql5.7.44-docker
参考msyql官方docker镜像制作

1、采用自编译MySQL的方式制作5.7.44的镜像，这样就能支持amd64和arm64架构的机器

2、修改了MySQL源码包里的boost的下载地址，是为了解决下载速度慢的问题。mysql-5.7.44/cmake/boost.cmake
```
SET(BOOST_DOWNLOAD_URL
  "https://archives.boost.io/release/1.59.0/source/${BOOST_TARBALL}"
  )
```

3、源码包里新增了个MySQL的默认配置。mysql-5.7.44/support-files/my-default.cnf
