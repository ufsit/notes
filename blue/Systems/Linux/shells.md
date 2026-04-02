# Jailbreaking

## Restricted environments

To prevent users from escalating, you can place them inside a restricted environment. However, these are often easy to break out of. One type is the **restricted shells** like `rsh`, which you can read about [here](https://tbhaxor.com/breaking-out-of-restricted-shell-environment/).

The other is a **chroot jail**, which limits what files you can accesss by changing your root directory. As long as you have access to:
1. A privileged shell
2. A program that can call **mkdir, chroot, chdir**

You can escape the jail, as shown [here](https://tbhaxor.com/breaking-out-of-chroot-jail-shell-environment/).