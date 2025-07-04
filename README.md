# SubEnum 🔍

**SubEnum** is a custom automation script for **subdomain enumeration** and **HTTP status checking**.  
It combines results from multiple powerful tools, removes duplicates, and checks the status and title of each subdomain.

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


