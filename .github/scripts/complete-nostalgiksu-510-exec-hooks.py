#!/usr/bin/env python3
import sys
from pathlib import Path


path = Path(sys.argv[1])
text = path.read_text()

required = (
    "ksu_handle_post_execveat_sucompat(&fd",
    "ksu_setup_preinit_file(&filename",
    "ksu_preinit_handle_post_execveat(&fd",
)
if all(name in text for name in required):
    print("Final NostalgiKSU exec hooks already present")
    raise SystemExit(0)

old_decls = """extern bool __ksu_is_allow_uid_for_current(uid_t uid);
extern int ksu_handle_execveat(int *fd, struct filename **filename_ptr, void *argv,
\t\t\tvoid *envp, int *flags);
extern int ksu_handle_execveat_sucompat(int *fd, struct filename **filename_ptr, void *argv,
\t\t\t\tvoid *envp, int *flags);
"""
new_decls = old_decls + """extern int ksu_handle_post_execveat_sucompat(int *fd, struct filename **filename_ptr, void *argv,
\t\t\t\tvoid *envp, int *flags, int *retval);
#ifndef KSU_NO_PREINIT
extern int ksu_setup_preinit_file(struct filename **filename_ptr, struct user_arg_ptr *argv_user);
extern int ksu_preinit_handle_post_execveat(int *fd, struct filename **filename_ptr,
\t\t\t\tvoid *argv_user, void *envp_user,
\t\t\t\tint *flags, int *retval, int *preinit_fd);
#endif // #ifndef KSU_NO_PREINIT
"""
if text.count(old_decls) != 1:
    raise SystemExit("unexpected Android 5.10 NostalgiKSU declaration layout")
text = text.replace(old_decls, new_decls, 1)

old_locals = "\tstruct linux_binprm *bprm;\n\tint retval;\n\n\tif (IS_ERR(filename))\n"
new_locals = """\tstruct linux_binprm *bprm;
\tint retval;
#ifdef CONFIG_KSU_SUSFS
\tbool is_su_session = false;
#ifndef KSU_NO_PREINIT
\tbool is_ksu_preinit_session = false;
\tint preinit_fd = 0;
#endif // #ifndef KSU_NO_PREINIT
#endif // #ifdef CONFIG_KSU_SUSFS

\tif (IS_ERR(filename))
"""
if text.count(old_locals) != 1:
    raise SystemExit("unexpected Android 5.10 do_execveat_common local layout")
text = text.replace(old_locals, new_locals, 1)

old_hook = """#ifdef CONFIG_KSU_SUSFS
\tif (likely(susfs_is_current_proc_umounted()))
\t\tgoto orig_flow;

\tif (static_branch_likely(&ksu_su_compat_enabled)) {
\t\tif (static_branch_unlikely(&susfs_is_sdcard_android_data_not_decrypted))
\t\t\tksu_handle_execveat(&fd, &filename, &argv, &envp, &flags);
\t\telse
\t\t\tksu_handle_execveat_sucompat(&fd, &filename, &argv, &envp, &flags);
\t}

orig_flow:
#endif
"""
new_hook = """#ifdef CONFIG_KSU_SUSFS
\tif (likely(susfs_is_current_proc_umounted()))
\t\tgoto orig_flow;

\tif (static_branch_likely(&ksu_su_compat_enabled)) {
\t\tif (static_branch_unlikely(&susfs_is_sdcard_android_data_not_decrypted)) {
\t\t\tis_su_session = !ksu_handle_execveat(&fd, &filename, &argv, &envp, &flags);
\t\t} else {
\t\t\tis_su_session = !ksu_handle_execveat_sucompat(&fd, &filename, &argv, &envp, &flags);
\t\t}
\t}

#ifndef KSU_NO_PREINIT
\tif (unlikely(current->pid == 1) && !is_su_session) {
\t\tif (fd == AT_FDCWD || !(flags & AT_EMPTY_PATH)) {
\t\t\tpreinit_fd = ksu_setup_preinit_file(&filename, &argv);
\t\t\tif (preinit_fd > 0)
\t\t\t\tis_ksu_preinit_session = true;
\t\t}
\t}
#endif // #ifndef KSU_NO_PREINIT

orig_flow:
#endif
"""
if text.count(old_hook) != 1:
    raise SystemExit("unexpected Android 5.10 SUSFS exec hook layout")
text = text.replace(old_hook, new_hook, 1)

old_post = "\tretval = bprm_execve(bprm, fd, filename, flags);\nout_free:\n"
new_post = """\tretval = bprm_execve(bprm, fd, filename, flags);
#ifdef CONFIG_KSU_SUSFS
\tif (unlikely(is_su_session))
\t\t(void)ksu_handle_post_execveat_sucompat(&fd, &filename, &argv, &envp, &flags, &retval);

#ifndef KSU_NO_PREINIT
\tif (unlikely(is_ksu_preinit_session)) {
\t\tif (ksu_preinit_handle_post_execveat(&fd, &filename, &argv, &envp, &flags,
\t\t\t\t\t\t      &retval, &preinit_fd)) {
\t\t\tfree_bprm(bprm);
\t\t\tis_ksu_preinit_session = false;
\t\t\tgoto orig_flow;
\t\t}
\t\tgoto out_free;
\t}
#endif // #ifndef KSU_NO_PREINIT
#endif // #ifdef CONFIG_KSU_SUSFS
out_free:
"""
if text.count(old_post) != 1:
    raise SystemExit("unexpected Android 5.10 bprm_execve layout")
text = text.replace(old_post, new_post, 1)

missing = [name for name in required if name not in text]
if missing:
    raise SystemExit(f"failed to install final NostalgiKSU exec hooks: {missing}")
path.write_text(text)
print("Installed NostalgiKSU 33197 Android 5.10 exec hook contract")
