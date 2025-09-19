所有脚本安装在目录 `~/.local/bin` 目录下，如果之前未创建这个目录，请先手动创建：

```shell
mkdir -p ~/.local/bin
```

确保 `~/.local/bin` 在环境变量中：
```shell
echo $PATH | tr ':' '\n'
# if not exist, execute the command below
echo 'export PATH="$HOME/.local/bin:$PATH"'
```

脚本自己将不提供直接的安装功能（你应该在查看相关脚本的具体功能后，再决定是否使用），需要手动链接，例如：

```shell
cd mac
chmod +x ./script_name.sh
ln -sf /absolute_path/script_name.sh $HOME/.local/bin/script_name
```

`-f` 会覆盖原有链接，`rm ~/.local/bin/script_name` 可以删除链接

makefile 用于查看 `~/.local/bin` 目录下已有的东西

本仓库中每个脚本应该是单独可运行的，可能存在使用其他仓库的脚本的情况，但不会出现当前脚本和其他同仓库脚本一起使用的情况

每个脚本文件在最前面会说明脚本作用
