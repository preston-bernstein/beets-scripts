# Beets Scripts for Music Library Management

## Overview

This repository contains a collection of scripts designed to work with Beets, an open-source music library manager. These scripts enhance the functionality of Beets by providing automated processes for removing duplicate files, organizing your music library, and maintaining a clean and efficient directory structure.

## Features

- **Remove Duplicate Files**: Intelligent duplicate removal based on normalized filenames, handling different delimiters (spaces, underscores, hyphens), and preferring filenames with spaces.
- **Organize Music Library**: Automatically organize your music files and directories according to specified rules.
- **Log Management**: Generate detailed logs for each script execution, including file and folder counts before and after operations, and maintain historical logs with timestamps.
- **Exclude System Directories**: Exclude special directories (e.g., @eaDir) from processing to avoid conflicts with system files.

## Scripts

1. **[remove_duplicates.sh](./remove_duplicates.sh)**
   - **Normalization Function**: Converts the name to lowercase, replaces non-alphanumeric characters with spaces, removes track numbers and disc numbers, and handles suffixes.
   - **File Quality Function**: Assigns a quality score to each file type (e.g., FLAC higher than MP3).
   - **Consolidate Album Tracks**: Processes each album directory to remove duplicate tracks, preferring higher quality versions, and moves the kept tracks to a consolidated directory.
   - **Consolidate Duplicates Across Albums**: Processes each album directory, normalizing the album names to compare and ensure duplicates are handled, preferring "Deluxe Edition" versions if available, and consolidates tracks.
   - Logs detailed information about the removal process and counts of files and folders.
   - Excludes system directories like @eaDir from processing.

## How to Use

### Clone the Repository

```bash
git clone https://github.com/yourusername/beets-scripts.git
cd beets-scripts
```

### Set Up Docker Environment

Ensure you have Docker installed and set up. Modify the provided Dockerfile and **`docker-compose.yml`** to suit your environment.

- **Dockerfile**

```Dockerfile
FROM lscr.io/linuxserver/beets:latest

# Copy the remove_duplicates.sh script into the container
COPY remove_duplicates.sh /config/remove_duplicates.sh
RUN chmod +x /config/remove_duplicates.sh

# Add cron job
RUN (crontab -l ; echo "0 3 * * * /config/remove_duplicates.sh") | crontab

ENTRYPOINT ["cron", "-f"]
```

- **docker-compose.yml**

```yaml
version: "3.3"
services:
  beets:
    image: custom-beets:latest
    container_name: Beets-Nord
    network_mode: "service:nordvpn"
    depends_on:
      - nordvpn
    volumes:
      - /path/to/your/config:/config
      - /path/to/your/music:/music
      - /path/to/your/downloads:/downloads
    environment:
      - PUID=1029
      - PGID=100
      - TZ=Your_Timezone
    mem_limit: 2g
    cpu_shares: 1024
    restart: always
```

### Build and Deploy

Build the custom Docker image and deploy the Docker Compose stack.

```bash
docker build -t custom-beets:latest .
docker-compose up -d
```

### Run the Script

Execute the **`remove_duplicates.sh`** script manually or set it up to run periodically via cron.

```bash
docker exec -it Beets-Nord /config/remove_duplicates.sh
```

### Monitor Logs

Check the log files generated in the **`/path/to/your/config`** directory:

```bash
ls /path/to/your/config
cat /path/to/your/config/remove_duplicates_*.log
```

## Contributing

Contributions are welcome! Please feel free to submit issues, fork the repository, and make pull requests to improve these scripts and add new functionality.

## License
This project is licensed under the MIT License. See the [LICENSE](./LICENSE) file for details.

## Acknowledgements

- [Beets](https://beets.io/?trk=public_post-text): The open-source music library manager used by these scripts.
- [LinuxServer.io](https://www.linuxserver.io/): For the Beets Docker image.
