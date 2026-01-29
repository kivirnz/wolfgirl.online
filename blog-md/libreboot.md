---
title: Librebooting, ThinkPads And Intel ME Hell
slug: libreboot
date: 2023-03-16
reading_time: 5 min read
---

Do you know why so many opsec enthusiasts use Lenovo Thinkpads? The reason why isn’t because they look cool (which they do), the reason why is because of something called the IME (Intel Management Engine)

Essentially ever since 2008, IME has been embedded in every single commercial and most industrial Intel chipsets for a while now. IME is an autonomous subsystem process running Minix (Linux predecessor built for embedded firmwares) which runs even when the device is powered off and it is responsible for things like handling NFC communications, anti-theft technology and Secure Boot cryptography.

“So” you may be asking, “do I need it on my system?” The answer is no.

Everything that IME can do is already handled by at least three other chips or pieces of software in your PC. No laptop really utilises NFC, Intel Anti-Theft Technology was discontinued in 2015 and Secure Boot is already handled by your BIOS. It serves zero purpose for existing.

“Hmm” you ponder, “that’s strange, if it has no reason to exist, then why does it exist in the first place?” Great question, the answer is to spy on you.

The EFF and many other internet privacy advocates have discovered that “the IME has full access to memory (without the owner-controlled CPU cores having any knowledge), and has full access to the TCP/IP stack and can send and receive network packets independently of the operating system, thus bypassing its firewall” In short, it has full access to every byte of data coming in and out of your system and you have zero control over it.

Intel responded against these claims pretty much saying “we would never put backdoors into our systems” but considering their biggest contracts are with government agencies I personally put this on the same level that pigs can fly.

Pile this on top of the fact that in the NSA Budget Request for 2013, they detailed a Sigint Enabling Project with the goal to “Insert vulnerabilities into commercial encryption systems, IT systems” and it is very much believed that this was referencing both IME and AMD’s similar product named the PSP (Platform Security Processor)

Pile that on top of (unconfirmed) leaked Mossad documents detailing research and collaboration with US Cyber Command to create a backdoor for IME and AMD PSP which results show were successful.

In short, it has every single byte of data in your device passing through it, and it has zero purpose other than to give glowniggers a way to spy on you, fantastic.

“Ok” you say “I gotta get rid of this now, is there a way to disable it?” Not officially…

Intel currently has zero support for people disabling the IME and they have stuck by that for many years, all the source code they use as well as the customised version of Minix they use for the embedded firmware is all closed source too. So how can we disable it?

There are a couple of ways:

*   Libreboot/Coreboot
*   me\_cleaner
*   HAP/undocumented mode

Let’s start with me\_cleaner, to put it very simply IME may sound scary but it is designed very very stupidly. The integrity verification system is broken, that is pretty much the part that allows the IME chip to check if it has been tampered with, and if it has detected it was tampered with, it forces the PC to shut down for 30 minutes. However there is a loophole where it gives you a grace period to re-flash the IME firmware and fix the problem. However this is where it gets stupid as if you corrupt the firmware of the IME just right, you can trigger it into an abnormal error state where the firmware is corrupted beyond repair but it does not shut down your system. Very very clever.

Now for the most ironic, HAP/undocumented mode. So Intel has blatantly admitted that the IME has a special mode in it known as ‘HAP mode’ (High-Assurance Platform mode) which was made for US government agencies to disable IME on their devices only and was only intended to be available only in machines produced for specific purchasers like the government agencies. The issue is even though there isn’t any public documentation by Intel, you can access the HAP mode on most retail Intel chipsets, essentially disabling IME simply because the government wanted it haha. Priceless. The HAP mode was quickly implemented into the me\_cleaner project though.

Now the third and most accessible way is via Libreboot/Coreboot. Coreboot is an BIOS replacement which is meant to replace OEM BIOS firmwares with a free and open source alternative. However Coreboot has an option to disable the IME partly using the me\_cleaner source code and partly their own funky magic. Meanwhile Libreboot automatically just disables the IME by default. Some devices can not completely disable the IME, but rather just heavily limit what information it stores and has access to, so that at maximum the IME can only receive 26 bytes of information a second, which doesn’t completely disable the IME but it does stunt it and make it essentially useless. Libreboot is a fork of Coreboot that does not allow binary blobs (binaries of proprietary software) which makes it slightly better. To install Libreboot or Coreboot, you need a CH341A programmer to write directly to the SPI flash of the BIOS chip. It is not a simple BIOS update sadly but it is very much worth it.

Back to the main point though, the reason why so many opsec enthusiasts use Thinkpads is that while there are builds for both Libreboot and Coreboot for many different devices including Macs and Chromebooks, the biggest range is on the Lenovo Thinkpad series, pair that with an award winning keyboard, cheap cost and the sheer volume manufactured, there is your recipe for why it is the goto for opsec enthusiasts.

In short, Intel ME (and AMD’s version of it known as PSP) are processes in your chipset running small embedded firmwares and every single byte of data in your computer has to travel through it. This makes the Intel ME a massive security burden as it is plagued with not only vulnerabilities but also backdoors which Intel were forced to install by government agencies. Intel makes it almost impossible to disable it but there are ways to do it and most of those methods work on old Thinkpads which is why they are so popular in opsec and internet privacy culture.

This has been Riley, signing out.