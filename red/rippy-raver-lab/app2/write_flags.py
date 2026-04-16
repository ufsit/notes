FLAG_12 = "flag12{rfi_sh3ll_fr0m_the_rav3_c4v3}"
FLAG_15 = "flag15{r00t_0f_the_rav3_y0u_0wn_the_syst3m}"


def write_flags():
    with open("flag12.txt", "w") as f:
        f.write(FLAG_12)
    
    # FLAG 15 — only readable after getting a shell
    with open("flag15.txt", "w") as f:
        f.write(FLAG_15)


write_flags()