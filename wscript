from os.path import dirname, join
import os

top = "."
out = "build"

class Dummy: pass


def configure(ctx):
    ctx.env.PATH = os.environ['PATH'].split(os.pathsep)
    ctx.env.PATH.append(join(ctx.cwd, "node_modules", "coffee-script", "bin"))
    ctx.find_program("coffee", var="COFFEE", path_list=ctx.env.PATH)
    ctx.env.ARGS = "-co"


def build(ctx):
    env = Dummy()
    env.variant = lambda: ""
    for top in ("src", "test"):
        for file in ctx.path.find_dir(top).ant_glob("**/*.coffee", flat=False):
            #print file.change_ext(".js").bldpath(env)
            tgtpath = file.change_ext(".js").bldpath(env)
            if top == "src":
                tgtpath = tgtpath[len(top)+2:]
            else:
                tgtpath = tgtpath[1:]
            ctx.path.exclusive_build_node(tgtpath)
            #print tgtpath
            ctx(name   = "coffee",
                rule   = "${COFFEE} ${ARGS} default/%s ${SRC}" %(dirname(tgtpath)),
                source = file.srcpath()[3:],
                target = tgtpath)
