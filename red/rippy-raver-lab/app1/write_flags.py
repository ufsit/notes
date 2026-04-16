import os
BASE_DIR   = os.path.dirname(os.path.abspath(__file__))
SECRET_DIR = os.path.join(BASE_DIR, "secret")

def write_secret_files():

    lfi_flag = os.path.join(SECRET_DIR, "flag4.txt")
    if not os.path.exists(lfi_flag):
        with open(lfi_flag, "w") as f:
            f.write("flag4{lf1_tr4v3rs4l_f1l3_r34d_rav3r_pwn3d}\n")

    # flag3 — IDOR flag
    idor_flag = os.path.join(SECRET_DIR, "user_1_private.txt")
    if not os.path.exists(idor_flag):
        with open(idor_flag, "w") as f:
            f.write("flag3{1d0r_4dm1n_pr1v4t3_n0t3_exf1ltr4t3d}\n")

    # flag5 — Log poison RCE flag
    rce_flag = os.path.join(SECRET_DIR, "flag5.txt")
    if not os.path.exists(rce_flag):
        with open(rce_flag, "w") as f:
            f.write("flag5{l0g_p01s0n_rce_rav3r_sh3ll_pwn3d}\n")

    # flag6 — File upload RCE flag
    upload_flag = os.path.join(SECRET_DIR, "flag6.txt")
    if not os.path.exists(upload_flag):
        with open(upload_flag, "w") as f:
            f.write("flag6{unr3str1ct3d_upl04d_sh3ll_pwn3d}\n")

    # flag9 — Root flag
    root_flag = os.path.join(SECRET_DIR, "flag9.txt")
    if not os.path.exists(root_flag):
        with open(root_flag, "w") as f:
            f.write("flag9{r00t_th3_rav3_pwn3d_th3_d4nc3fl00r}\n")

write_secret_files()