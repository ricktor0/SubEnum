# SubEnum 🔍

**SubEnum** is a custom automation script for **subdomain enumeration** and **HTTP status checking**. It combines results from multiple powerful tools, removes duplicates, and checks the status and title of each subdomain.

---

## 🚀 Features

- Combines results from:
  - [Assetfinder](https://github.com/tomnomnom/assetfinder)
  - [Subfinder](https://github.com/projectdiscovery/subfinder)
  - [Sublist3r](https://github.com/aboul3la/Sublist3r)
- Removes duplicate subdomains
- Uses [httpx](https://github.com/projectdiscovery/httpx) to:
  - Check HTTP/S status codes
  - Grab page titles
- Saves results in organized files

---

## 🛠 Requirements

Install these tools and make sure their paths are correct in the script:

| Tool         | Installation Link                                          |
|-------------|------------------------------------------------------------|
| Assetfinder | https://github.com/tomnomnom/assetfinder                   |
| Subfinder   | https://github.com/projectdiscovery/subfinder              |
| Sublist3r   | https://github.com/aboul3la/Sublist3r                      |
| httpx       | https://github.com/projectdiscovery/httpx                  |
| Python3     | https://www.python.org/downloads/                          |
---

## ⚙️ Usage

### 1️⃣ Clone the Repository

```bash
git clone https://github.com/ricktor0/subenum.git
cd subenum
chmod +x subenum.sh
```

### 2️⃣ Configure the Tool Paths
Open the script subenum.sh in any text editor and update these variables to match your system:
```bash
ASSETFINDER_PATH="/home/r1ckt0r/go/bin/assetfinder"
SUBLIST3R_PATH="/home/r1ckt0r/Sublist3r/sublist3r.py"
SUBFINDER_PATH="/home/r1ckt0r/go/bin/subfinder"
HTTPX_PATH="/home/r1ckt0r/go/bin/httpx"
```

### 3️⃣ Run subenum
```bash
./subenum.sh target.com
```
### This will:

- Run Assetfinder, Subfinder, and Sublist3r
- Merge and deduplicate results
- Check subdomains with httpx
- Save everything inside the output/ folder
  
## 🔥 Output

```bash
r1ckt0r@ubuntumachine:~/subenum$ ./subenum.sh evil.com
[+] Running assetfinder...
[+] Running sublist3r...

                 ____        _     _ _     _   _____
                / ___| _   _| |__ | (_)___| |_|___ / _ __
                \___ \| | | | '_ \| | / __| __| |_ \| '__|
                 ___) | |_| | |_) | | \__ \ |_ ___) | |
                |____/ \__,_|_.__/|_|_|___/\__|____/|_|

                # Coded By Ahmed Aboul-Ela - @aboul3la
    
[-] Enumerating subdomains now for evil.com
[-] Searching now in Baidu..
[-] Searching now in Yahoo..
[-] Searching now in Google..
[-] Searching now in Bing..
[-] Searching now in Ask..
[-] Searching now in Netcraft..
[-] Searching now in DNSdumpster..
[-] Searching now in Virustotal..
[-] Searching now in ThreatCrowd..
[-] Searching now in SSL Certificates..
[-] Searching now in PassiveDNS..
[-] Saving results to file: ./output/sublist3r_temp.txt
[-] Total Unique Subdomains Found: 4
www.evil.com
us1.defend.egress.com.evil.com
miro.com.evil.com
www.spacex.com.evil.com
[+] Running subfinder...
[+] Removing duplicates...
[+] Running httpx on unique subdomains...
[+] Done! Results saved in: ./output/evil.com_httpx.txt
```
## 👀 Feel free to add more tools. 

