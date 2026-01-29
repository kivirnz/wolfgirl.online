---
title: My Weird Journey Investigating PyInstaller Malware In Bulk
slug: pyinstaller
date: 2024-12-02
reading_time: 24 min read
---

Hey everyone, today I have a bit of a long but interesting story regarding malware research.

It all started one day in an infostealer log chat I’m in on Telegram. People share infostealer logs back and forth, ask if anybody has valid cookies for X service, sell their SMTP credentials etc.

People also regularly share their log checker/cookie checker scripts in this chat for free too (although they quickly get deleted by chat admins for reasons which will soon become apparent). Now, you may be asking “why in the world would anybody give away these tools which check infostealer logs against services for their validity for free?”. The answer for that is very simple, it’s quite easy to see that these log checker scripts are infostealer malware themselves, primarily looking to target skids who have little to no experience with industry-tried-and-tested tools for this like SilverBullet or OpenBullet.

**Investigating NETFLIXER-v3.1.exe**
====================================

But regardless, one day in this infostealer log chat on Telegram, somebody posted one of these log checker scripts for Netflix. The goal of this program was essentially to import a list of infostealer logs meant for Netflix (in URL:EMAIL:PASS format), and tell you which ones were valid. Knowing full well that this was very likely malware itself, I decided to download it and reverse engineer it to see what I could find.

This program was called ‘NETFLIXER-v3.1.exe’, the very curious amongst you may have realized the icon for this program.

![captionless image](https://miro.medium.com/v2/resize:fit:188/format:webp/1*feYwxuA3pNB5TAug6a8lig.png)

This is indeed a PyInstaller script! PyInstaller is a common Python-to-Windows-executable library which essentially compiles Python code into a .pyc format and includes a small copy of Python 3 in the executable so it can execute Python code on a machine instantly without having to worry about installing Python or Python dependencies beforehand. So the first step to this is to extract the .exe into the raw compiled .pyc files. Thankfully, there is a helpful tool to do this called [pyinstxtractor](https://github.com/extremecoders-re/pyinstxtractor) which serves this exact purpose. So by running:

    pyinstxtractor NETFLIXER-v3.1.exe

We can then get the whole source code of this program!

![captionless image](https://miro.medium.com/v2/resize:fit:1400/format:webp/1*Hq88a_8RAkx_WihhV3pERQ.png)

As the final line tells us, because the files are compiled (which makes them unreadable), we need to decompile them first. Python decompilation is unfortunately a bit trickier than it seems. Each individual version of Python has a unique bytecode associated with it, and when you try to decompile a compiled Python script, your PC must be on the same version of Python that the code was written in. Thankfully, there is an easy way to find this out. As I said earlier, a small Python binary is always included in a PyInstaller program in a .dll file, so we can just look in the extracted folder than pyinstxtractor made to see which version of Python this was coded in:

![captionless image](https://miro.medium.com/v2/resize:fit:1400/format:webp/1*k7RXJ1R8OuIhwEjDK_Vn6w.png)

And as we can see, this was coded in Python 3.12. Sadly though, the issue is that I am running Python 3.13 so I can’t decompile it. Theoretically I could spin up a Docker container with Python 3.12 and decompile it that way but that is far too much hassle, so instead I opted for a different method.

After a bit of Googling, I found [PyLingual](https://pylingual.io/). A new webapp made by [Josh Wiedemeier, Tarbet Elliot, Zheng Max, Ko Sangsoo, Ouyang Jessica, Cha Sang Kil and Kangkook Jee](https://www.computer.org/csdl/proceedings-article/sp/2025/223600a052/21B7QZB86cg), a group of researchers at the University of Texas. It’s basically a webapp which is able to decompile any .pyc file, regardless of the version. Unfortunately, they haven’t released many details as to how this program works and it is closed-source for now. But my best guess would be that it uses a VPS with all the different Python 3 versions and matches the bytecode from the .pyc with a specific version to decompile it. Regardless though, it is a very useful tool. Many thanks to the team for creating it.

The only downside with PyLingual though is that you have to upload .pyc’s to decompile one at a time, you can’t do them all at once. So I had to decide which .pyc file in the extracted folder looked out of place. So after a brief glance, I noticed that the file named ‘passwords.pyc’ looked extremely out of the ordinary, so I decided to decompile that one first.

And little do you know, here is the decompiled passwords.pyc in all of it’s skid-tier glory!

![captionless image](https://miro.medium.com/v2/resize:fit:1400/format:webp/1*8Lf1X_djRxRRHBX7fZSSMA.png)

And just as I thought, it is indeed an infostealer. Having a function named ‘**get\_chrome\_passwords**’ where it retrieves autofill passwords from Chrome’s local SQLite database is not the best idea:

![captionless image](https://miro.medium.com/v2/resize:fit:1400/format:webp/1*gjCN__IOigtajCqep7BdHA.png)

However, upon looking into this script more, I found something interesting. It doesn’t use a typical C2 like Lumma, Racoon or Redline does, instead, it has a function named ‘**send\_file\_via\_telegram**’ where it uses a Telegram bot to send the logs to via Telegram’s API:

![captionless image](https://miro.medium.com/v2/resize:fit:1400/format:webp/1*HPjhxHDYPhvlYhJoKDKO2A.png)

What really interested me is that the bot token was left in plaintext, it wasn’t obfuscated at all. This is a really bad idea because with this bot token, it allows you to dump the entire history of the Telegram bot, so we can see exactly what type of people fall for this malware.

Thankfully, [soxoj](https://github.com/soxoj) (the same mastermind behind the amazing [Maigret](https://github.com/soxoj/maigret) OSINT tool) made a [script](https://github.com/soxoj/telegram-bot-dumper) to do exactly that, to dump a Telegram bot’s full history based on the bot token. But when I first tried to make a direct API call to Telegram to get basic information about the bot, I encountered an issue:

![captionless image](https://miro.medium.com/v2/resize:fit:1400/format:webp/1*m1HwFnzlOXIi3gudASU6Bw.png)

It looks like the bot isn’t valid, from my previous experience, this is most likely because the private key (the part after the colon) has been refreshed. Trying this again with soxoj’s [telegram-bot-dumper](https://github.com/soxoj/telegram-bot-dumper) script has led me to the same conclusion:

![captionless image](https://miro.medium.com/v2/resize:fit:632/format:webp/1*dJPXZwZOj9ljQysJtAk2UQ.png)

So, on the bright side, this means that any logs from the victim’s PC won’t ever be sent to anyone as it’s simply cannot reach the bot. On the down side though, we won’t get to see the history of the bot ourselves. So that is where I will leave this.

My final conclusion is that this is an extremely run of the mill Python-based infostealer. It doesn’t match any fingerprints or signatures of more common infostealers (i.e. Lumma, Racoon, Redline) but judging by the names of the functions (i.e. send\_file\_via\_telegram, get\_chrome\_passwords), it looks like this was coded in ChatGPT. Regardless, it is essentially a dead malware because the Telegram bot it exfiltrates the logs to is now dead. Interesting case, but let’s move onto the next one.

**Investigating Praser.exe**
============================

Firstly, before I get into this one, I do have to give a quick shout out to [0xVulp](https://natangrygiel.pl/en/). A long time friend of mine who decided to embark on this silly journey with me after sharing my discoveries with the NETFLIXER malware. Truly awesome guy and he helped me out tons with this, shout out to him.

After my initial discovery with the NETFLIXER malware, I decided to go out on a hunt for more as I was getting really into this. But I found the NETFLIXER malware randomly in a Telegram chat, how could I find more?

The answer to this question was simple. Telegram CSEs. For those of you unaware, CSE stands for **C**ustom **S**earch **E**ngine. Google allows for you to create these easily. Basically, imagine Google dorking, but with the dorks already included in your parameters, so you can look for anything within a certain scope. The issue with Telegram is that a lot of data from public channels are publicly accessible via web crawling. For example, if you wish to go to a certain channel on Telegram, you just need to input ‘t.me/channel\_name\_here’ in your browser and Telegram will automatically use its tg:// URI to redirect you to that channel on your Telegram app. The only issue with this is that the ‘t.me/channel\_name\_here’ endpoint won’t give you information about what’s actually on the channel, it will just show you the channel icon, name, description and subscriber count. But thankfully, there is another endpoint which will show you the content of a public channel too, it’s under ‘t.me\*\*/s/\*\*channel\_name\_here’. Here I will use a random public meme channel I’m in ([@x21edge](https://t.me/x21edge)) as an example:

![https://t.me/x21edge](https://miro.medium.com/v2/resize:fit:1400/format:webp/1*hPkunhyoM14ZP8EA2aRkaA.png)![https://t.me/s/x21edge](https://miro.medium.com/v2/resize:fit:1400/format:webp/1*jDLC9cn0FT8m2sOnAEHG-g.png)

So, following this theory, if we did a Google dork for inurl:”t.me/s/”, we would get all the public Telegram channels that have been cached by Google:

![captionless image](https://miro.medium.com/v2/resize:fit:1400/format:webp/1*hX7hpf7VV8lA-ZzYPUh7dw.png)

But we are not interested in channels about the Syrian Civil War (although that is a very interesting topic), we are interested in channels that have these ‘log checker’ malware programs. So this is where Telegram CSEs come in handy as they are able to refine these desired results far better than any dork could. Thankfully, there are a few different Telegram CSEs available, such as the ones [here](https://cse.google.com/cse?cx=006368593537057042503%3Aig4r3rz35qi#gsc.tab=0), [here](https://cse.google.com/cse?cx=6c3e0c0d3da8e3b4a), [here](https://cse.google.com/cse?q=+&cx=006368593537057042503%3Aefxu7xprihg#gsc.tab=0&gsc.q=%20&gsc.page=1) and [here](https://cse.google.com/cse?cx=004805129374225513871%3Ap8lhfo0g3hg). From these, we can search for stuff such as ‘steam logs checker’ and get a bunch of these Telegram channels hosting similar malware:

![captionless image](https://miro.medium.com/v2/resize:fit:1328/format:webp/1*7R_NSxf7yLJze-ycSi1crQ.png)

Upon further digging in these CSEs, I found a Telegram channel under the name of [@HackerAviatorPro](https://t.me/HackerAviatorPro) which is absolutely rife with these kinds of malware.

![From my DMs with 0xVulp](https://miro.medium.com/v2/resize:fit:500/format:webp/1*WukBfqGtjXdXz9As3MIKZw.png)

So from there, I downloaded them all and started digging.

![captionless image](https://miro.medium.com/v2/resize:fit:1190/format:webp/1*nlcIuSbevztn4DmKsUtrag.png)

I should point out that it was around this time when 0xVulp had another great idea too, he thought of looking for YouTube videos with the title of ‘2024 crack free download full version’ and downloading those too. I’m currently still in the process of reverse engineering those and that will be in a follow up article. But I opted for the CSE method of malware harvesting as it was just a lot faster and I didn’t have to jump through all the paywalls which the YouTube malware download links had to download it.

Continuing on though, I already noticed a few pieces of malware with the default PyInstaller icon in them, but I am also aware that it is possible to change the default icon too. What makes it slightly more tough is that not all of these pieces of malware are PyInstaller based, a lot of them opt for Visual Basic or other languages. But since there is no easy way to tell, I wrote a simple Bash script to run pyinstxtractor on all of them. The ones that aren’t based on PyInstaller will fail, and the ones that are based on PyInstaller will work.

    #!/bin/bash
    for exe in *.exe; do
     if [[ -f “$exe” ]]; then
     echo “Getting compiled Python shit from $exe”
     pyinstxtractor “$exe”
     else
     echo “There are no exe’s in here dumbass”
     exit 1
     fi
    done
    echo “All done”

![captionless image](https://miro.medium.com/v2/resize:fit:462/format:webp/1*5i-BIc0KyapH6PEEcFB5Tg.png)

Pretty soon after, it finished and it found 8 pieces of malware which were run via PyInstaller, all except 3 had the default PyInstaller icon. We’ve already investigated NETFLIXER-v3.1.exe, so let’s move onto the others.

One that really interested me was called Praser.exe simply because of the short and weird name. But upon further thinking, I realized that somebody most likely misspelled the word ‘Parser’. Infostealer log parser tools are common in the skid world because contrary to popular belief, infostealer logs come in many different formats. Most of them are simply URL:USER:PASS, but some of them are USER:PASS:URL, and others are:

> URL: [https://website.com/login](https://website.com/login)
> 
> Username: admin
> 
> Password: admin

So parsers are quite common utilities to convert all these different infostealer log formats into one to make them more readable by checkers. The same as with I explained earlier about checkers being easily replaced by tools like SilverBullet though, parsers can be easily replaced by tools like [ripgrep](https://github.com/BurntSushi/ripgrep) and a tiny bit of syntax and regex knowledge. Yet skids don’t wish to put in the effort to learn this, so they use these malware-ridden tools like this instead. Anyways, onto reverse engineering it.

The only file that looked out of the ordinary in the extracted folder was called ‘swa.pyc’:

![captionless image](https://miro.medium.com/v2/resize:fit:1400/format:webp/1*p10suRlxJ4Aj9XCXMv-nmg.png)

As we can see from the .dll file, this was written in Python 3.8 so we have no way of decompiling this ourselves, back to [PyLingual](https://pylingual.io) we go!

![It never fails me istg](https://miro.medium.com/v2/resize:fit:1400/format:webp/1*OgSY8YS8kBR7hyOGA5rLHA.png)

Yet again, judging by the function names, this looks like more ChatGPT-written malware, but still we press on.

Russian IP Address Investigation
--------------------------------

I sent the decompiled swa.py file to 0xVulp before I headed to sleep for the night, and in the morning he found something interesting:

![Screenshot courtesy of 0xVulp](https://miro.medium.com/v2/resize:fit:1258/format:webp/1*Q4zZHH2agWLbFaz_cOu_FA.png)

It has a function called ‘download\_and\_execute\_exe’ which, from my supreme eternal wisdom, is supposedly meant to download and execute this ‘nuke.exe’ file (who would have guessed). The thing that intrigued both myself and 0xVulp though, is that it isn’t downloaded from a domain, it’s downloaded from an IP. This IP is hosted in Russia. But what’s more interesting is who’s hosting it. After a quick search on Shodan, we can find this information:

![captionless image](https://miro.medium.com/v2/resize:fit:1400/format:webp/1*6fT6dIBhuFqGOe5o0T0ZOg.png)

We can see that the company who owns this IP is called ‘Chang Way Technologies Co. Limited’. After a quick Google search on this company, we found this very interesting Medium article written by Joshua Penny: [https://medium.com/@joshuapenny88/hostinghunter-series-chang-way-technologies-co-limited-a9ba4fce0f65](https://medium.com/@joshuapenny88/hostinghunter-series-chang-way-technologies-co-limited-a9ba4fce0f65)

‘Chang Way Technologies Co. Limited’ (who I will refer to as Chang Way from now on), is a Hong Kong-based shell company who offer web hosting services with their servers based mainly in Russia (Saint Petersburg and Moscow to be exact) and a few in Hong Kong, it is run by an individual named Victor Zaycev. Chang Way is the hosting companies trading name, but online they are known to sell their hosting service under the names ‘UNDERGROUND’ and ‘BearHost’. Joshua Penny traced an email address found for Chang Way back to Telegram and found several connected accounts:

![Screenshot courtesy of Joshua Penny](https://miro.medium.com/v2/resize:fit:1400/format:webp/1*BJoEF0fRmK7bDOVLoq4ttA.png)

The fact that they name their hosting service ‘UNDERGROUND’ and that they label their servers as ‘Bulletproof’, really drives home the idea that this is a hosting company marketed directly towards people looking to host C2s. You won’t find any regular Russian mom-and-pop shops hosted on their CIDR, just malware and C2s, lovely.

But anyways, our goal isn’t to do OSINT on an ASN, it’s to reverse engineer this malware. So going back to the ‘nuke.exe’ we found, running strings on nuke.exe revealed something interesting:

![Screenshot courtesy of 0xVulp](https://miro.medium.com/v2/resize:fit:1400/format:webp/1*fLsHicDU17GjxsOmmsi1ZA.png)

It mentions what I can only assume is a person named ‘ZeroX64’ (who will become important later into the story) and a note saying that it was ‘Made in Algeria ❤’. Due to a couple of reasons that I will get to later, I heavily doubt that this malware was made in Algeria, I believe for this to be a detrace (a process where a user tries to disguise their identity by faking being in another location for the purpose of anonymity). Anyhow, the rest of the strings don’t reveal anything interesting at all. So the next step would be to run this malware in a sandboxed environment to find out exactly what it does. Off to [any.run](https://app.any.run) we go!

And by gosh, there is a lot here to analyze.

Sandboxed VM Analysis
---------------------

![captionless image](https://miro.medium.com/v2/resize:fit:1400/format:webp/1*KZ-0nWq5i3oCRAt2rGiO_A.png)![captionless image](https://miro.medium.com/v2/resize:fit:1400/format:webp/1*P4pxwcbET2igAtQ5lDkvkg.png)

We will get to the network requests in a second, but first let’s look at the process it takes to launch this executable. The first thing that intrigued me was very much a ‘what the dog doin?’ moment. Looking at what nuke.exe does, it takes a very interesting path:

![captionless image](https://miro.medium.com/v2/resize:fit:658/format:webp/1*AWrRMl2uV4sbVhRJLrisrQ.png)

It seems to do a couple of things, namely:

*   Drops the nuke.exe file in %USERPROFILE%\\AppData\\Roaming\\2F33566DA0B91573532102\\2F33566DA0B91573532102.exe (may be a dynamic hash of some sort, will get to this later as it is important)
*   Edits the registry to inject this file into startup via multiple system modules (svchost.exe, msiexec.exe, audiodg.exe)
*   Checks for supported languages??????????

![captionless image](https://miro.medium.com/v2/resize:fit:1034/format:webp/1*25H1r8VhEPaFsZvfOsQECQ.png)

For the last step before it messes with system TRUSTEDINSTALLER-level modules, it tries to see which languages are built into the system. This is actually not as uncommon as you might believe. As [security researcher Brian Krebs covered in 2021](https://krebsonsecurity.com/2021/05/try-this-one-weird-trick-russian-hackers-hate/), Russian cybercrime laws work very weirdly. There is a bit of an unspoken, golden rule in the Russian cybercrime world which roughly translates to [‘don’t work in .ru’](https://www.nytimes.com/2021/05/29/world/europe/ransomware-russia-darkside.html). What this means is that historically, the Russian ФСБ and ГРУ intelligence agencies have openly said to ransomware gangs “Do whatever the fuck you want to the rest of the world, we will rarely ever care. The second you touch anything in Russia (and more recently the CIS region), we will make sure that you never see the light of day again”. Because of this, Russian-developed malware/ransomware often have a feature included in it to check if the person it is infecting is Russian/CIS-based by which language packs they have installed on their PC. If it detects a Russian/Kazakh/\*stan language pack installed on the system, it automatically will not run the malware/ransomware because the risk of getting caught violating this golden rule is too great, even for malware/ransomware operators.

![К счастью, я как русскоязычный, от этого в любом случае застрахован)))](https://miro.medium.com/v2/resize:fit:584/format:webp/1*Yj-socXIl5kgTC8vT_KL9A.png)

But that’s about as much as the process analysis will give us. The next step would be to see which network requests the malware is making. The thing that really interested me is that the first thing it does is make a request to download a file from the same IP that hosted nuke.exe, called bot64.bin. Then after this, it makes a request to a PHP file on the same IP with the hash from where it dropped the nuke.exe earlier in the request parameter (this URL will be called VzCAHn.php for reference).

![captionless image](https://miro.medium.com/v2/resize:fit:748/format:webp/1*R0qF-E9lWruB40QiBYkQig.png)

From a GET request to VzCAHn.php (with the hash parameter attached) it simply returns another hash.

![captionless image](https://miro.medium.com/v2/resize:fit:1364/format:webp/1*k4qoUuqJCY1TaJ36NIR8SQ.png)

After that, it then sends a random octet-stream (which I assume is generated on the PC) in a POST request to VzCAHn.php.

![captionless image](https://miro.medium.com/v2/resize:fit:1400/format:webp/1*eYzSUhAC3aSSpNZ7BaRGcw.png)

So, to break this down:

1.  nuke.exe executes, generates a hash that it renames itself to (in my case 2F33566DA0B91573532102)
2.  It sends a GET request for a file called bot64.bin (to which nuke.exe presumably executes it)
3.  It then sends a request to VzCAHn.php on the same IP address with the hash (2F33566DA0B91573532102) in the request parameters. The response is another hash (in my case 59e9eda3304cb32135def480ea119a1e29593128)
4.  bot64.bin then generates a small binary and sends it in a POST request to the same VzCAHn.php endpoint
5.  That’s it

Interestingly though, 0xVulp found something quite odd. If you resend the same POST request to the VzCAHn.php endpoint with the same binary attached, it gives you a weird error.

![captionless image](https://miro.medium.com/v2/resize:fit:1400/format:webp/1*5fuMbpQVWMVdYz4lcG5rhQ.png)

So from this, we know that the binary file it sends is referred to as a ‘uhid’ in the database, and we get a full system path to the VzCAHn.php endpoint.

The next step was to reverse engineer this bot64.bin myself though. So I booted up IDA to disassemble it, and that’s when I got a weird message.

![captionless image](https://miro.medium.com/v2/resize:fit:638/format:webp/1*cIJ0SptTsk_SpjPHO9_G0g.png)

It is looking for a symbol file with debug information, but it’s looking for it on the same filepath as the developer. This inadvertently reveals the developers name as ‘Diamotrix’ which is interesting to note. From there, 0xVulp found an interesting [threat intel report](https://redpiranha.net/sites/default/files/2024-09/Threat%20Intel%20Report%20Sept%203%20-%209_0.pdf) by RedPiranha which directly mentions Diamotrix.

![captionless image](https://miro.medium.com/v2/resize:fit:1400/format:webp/1*6YrUnUMhT7PRHm2BwREccw.png)

RedPiranha claims that they found a malware sample which they have named ‘Diamotrix Clipper’. I was quite surprised when I saw this because I had my heart set on this being infostealer malware, not a clipper.

For those of you unaware, clipper malware is quite interesting. Essentially how it works is that, let’s say you’re sending some BTC from walletaddress1 to walletaddress2. Bob, who owns walletaddress2, sends you his wallet address so you can transfer the money, so you highlight it and hit Ctrl+C to copy it to your clipboard. What clipper malware does is it uses a regex to detect anything which looks like a wallet address in your clipboard, and then it replaces it with the attackers wallet address, so when you paste Bob’s address into your wallet to transfer the funds, you would think that you have pasted Bob’s wallet address, but in fact the malware replaces Bob’s address with it’s own, sending all the crypto that is supposed to go to Bob directly to the attacker.

![captionless image](https://miro.medium.com/v2/resize:fit:1400/format:webp/1*BZRCk5bwm3LKM4tB1aThbg.jpeg)

However one thing really stumped me, I originally didn’t believe that this is a clipper. Because of all the requests it makes to VzCAHn.php, it seems like something much more akin to an infostealer if it’s making that many requests. Typically, a clipper would need to make next to no requests to a C2, especially not at that frequency.

With this in mind though, I continued looking through the source code on IDA.

IDA Analysis & Crypto Tracing
-----------------------------

![captionless image](https://miro.medium.com/v2/resize:fit:1354/format:webp/1*zqZXtIrCtPhW7GwwUFuquw.png)

By looking at the strings and tracing them back to memory addresses, we can see the IP from earlier mentioned, as well as another IP on the same Chang Net host but I didn’t look into that. We can also see the VzCAHn.php file it calls mentioned too, as well as a bunch of .dll files it checks for.

But more interestingly, something else came up!

![captionless image](https://miro.medium.com/v2/resize:fit:1400/format:webp/1*3Ov5WlLCl0Rsykbp6JEOnw.png)

This is indeed a clipper malware, not an infostealer malware like I originally thought. I guess RedPiranha was right about something! From here, we can see regex’s for crypto wallet addresses, addresses to replace it with, as well as WinAPI calls to set, empty and get clipboard data.

From here, we can just look at these wallet addresses on the Blockchain to see exactly how much money this malware developer is making. The issue is only 3 of the 6 addresses they listed were actually valid on the Blockchain, with one being Bitcoin Cash, another being Dogecoin and another being Dash.

![captionless image](https://miro.medium.com/v2/resize:fit:1400/format:webp/1*7lIU_gxDyKHhP8jju3QqPQ.png)

All of the wallets are empty though with no recorded history which leaves me to 1 of 2 conclusions. Either:

1.  This poor malware dev has had absolutely no luck
2.  This is very fresh malware and the wallets are very new

Either way, the dude has made no money from this (yet).

So, this wraps up most of the investigation, we found out that Praser.exe downloads a malware called nuke.exe from a Russian IP, the ISP that hosts it is dodgy as fuck, nuke.exe downloads bot64.bin and adds it to startup, bot64.bin is clipper malware. Simple.

But there was one question that still lingered in my mind… who the hell is ZeroX64/Diamotrix? Did ZeroX64 make Praser.exe and Diamotrix made the clipper? Are they the same person?

Contacting The Developer
------------------------

So, this led me to an account on Telegram under the handle [@Diamotrix](https://t.me/Diamotrix), and guess what, they also go by the name ZeroX64!

![captionless image](https://miro.medium.com/v2/resize:fit:866/format:webp/1*oLJ4j8nOWbHAFin4TDAaHQ.png)

So, I exchanged a few messages with them. The first few in Russian because I was trying to confirm my hunch that the ‘Made in Algeria ❤’ thing was a detrace due to the language checking function from earlier, but they didn’t understand it so I wrote the rest in English.

![captionless image](https://miro.medium.com/v2/resize:fit:1400/format:webp/1*VXQ80dsdiDodtdHXC_lgBA.png)![captionless image](https://miro.medium.com/v2/resize:fit:1400/format:webp/1*BM-3C539LXMBMaLYQ7kfzw.png)

He was actually a very polite guy and I’m surprised that he didn’t instantly block me. He explained to me how he made it and how the bot64.bin was obfuscated (XOR). He also explained that he originally made an infostealer payload named xstealer.bin but he got ‘flooded with logs’ so he opted to change it to a clipper payload instead. This got me thinking though. I didn’t even think about checking the certificate transparency logs for the IP to see which other files are hosted there, maybe I could find the xstealer.bin.

So with that, I found the IP in [URLhaus](https://urlhaus.abuse.ch) and it listed a bunch of other files hosted on the server:

![captionless image](https://miro.medium.com/v2/resize:fit:1400/format:webp/1*U9n72FkwkDhcfJO5_EF7Jg.png)

Amongst these was one called xstealer.bin, but I will explore that in a future article. But regardless, it’s interesting to know that this is a diverse and wide-reaching malware operation.

This is where 0xVulp decided to message ZeroX64/Diamotrix to ask his own questions. This is where something big was revealed.

TinyNuke
--------

![captionless image](https://miro.medium.com/v2/resize:fit:868/format:webp/1*VNQyZ_2eTUROHVaX7AbTuw.png)

So apparently, this malware utilizes a well-known banking trojan called [TinyNuke](https://malpedia.caad.fkie.fraunhofer.de/details/win.tinynuke). TinyNuke is a common banking trojan which was first detected in 2017 but laid dormant for a significant amount of time. Then in 2019, it was revealed that the creator of TinyNuke, a French citizen who was identified as Augustin Inzirillo, was arrested in a sextortion case in France.

![A tweet made by Augustin Inzirillo, the TinyNuke developer in 2018](https://miro.medium.com/v2/resize:fit:1400/format:webp/1*Yx8fwbv-vj4rOSuB0cvl0g.png)

Then in 2021, TinyNuke resurfaced in the malware world as it was documented that it began to target French companies. The impact that this malware had on these companies is unknown, but regardless, the source code for TinyNuke was eventually leaked onto [GitHub](https://github.com/rossja/TinyNuke), and I’m guessing this is where ZeroX64/Diamotrix got it from and decided to incorporate into his malware.

To quote 0xVulp who summed it up so perfectly: “this shit is like a movie”

But that marks the end of this journey into exploring PyInstaller malware, please stay tuned for the next part (whenever it comes)

**Thank you very much for taking the time to read this article! I’d appreciate it if you shared it to friends, colleagues or anyone else who might find this interesting.**