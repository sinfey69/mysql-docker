# mysql-5.5.62

1、采用自编译MySQL的方式制作5.5.62的镜像，这样就能支持amd64和arm64架构的机器

2、修改了MySQL源码，解决新版gcc编译不兼容旧版gcc4.8的问题。mysql-5.5.62/sql-common/client_plugin.c
```
--- mysql-5.5.62.orig/sql-common/client_plugin.c
+++ mysql-5.5.62/sql-common/client_plugin.c
@@ -233,6 +233,7 @@ int mysql_client_plugin_init()
 {
   MYSQL mysql;
   struct st_mysql_client_plugin **builtin;
+  va_list dummy;
 
   if (initialized)
     return 0;
@@ -249,7 +250,7 @@ int mysql_client_plugin_init()
   pthread_mutex_lock(&LOCK_load_client_plugin);
 
   for (builtin= mysql_client_builtins; *builtin; builtin++)
-    add_plugin(&mysql, *builtin, 0, 0, 0);
+    add_plugin(&mysql, *builtin, 0, 0, dummy);
 
   pthread_mutex_unlock(&LOCK_load_client_plugin);
 
@@ -293,6 +294,7 @@ struct st_mysql_client_plugin *
 mysql_client_register_plugin(MYSQL *mysql,
                              struct st_mysql_client_plugin *plugin)
 {
+  va_list dummy;
   if (is_not_initialized(mysql, plugin->name))
     return NULL;
 
@@ -307,7 +309,7 @@ mysql_client_register_plugin(MYSQL *mysq
     plugin= NULL;
   }
   else
-    plugin= add_plugin(mysql, plugin, 0, 0, 0);
+    plugin= add_plugin(mysql, plugin, 0, 0, dummy);
 
   pthread_mutex_unlock(&LOCK_load_client_plugin);
   return plugin;
```

3、构建和执行
```
docker build -t menzai/mysql-5.5.62:v1 .

docker run -p 3306:3306 -d -e MYSQL_ROOT_PASSWORD=a123456 --name mysql5.5.62 -it menzai/menzai/mysql-5.5.62:v1
```

4、官方Dockerfile文件及自启动文件https://github.com/docker-library/mysql/commit/98f958b67cf45af464c3ad4521a1e2af71398650