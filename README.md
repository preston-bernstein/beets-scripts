# beets-scripts

A duplicate-removal script for music libraries managed with [Beets](https://beets.io/), designed to run inside a [linuxserver/beets](https://docs.linuxserver.io/images/docker-beets/) Docker container.

[![CI](https://github.com/preston-bernstein/beets-scripts/actions/workflows/ci.yml/badge.svg)](https://github.com/preston-bernstein/beets-scripts/actions/workflows/ci.yml)  [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## What it does

[`remove_duplicates.sh`](remove_duplicates.sh) walks a music library laid out as `Artist/Album/Track` and:

1. Normalizes track and album names (case, punctuation, track/disc numbers) so near-identical files compare equal regardless of naming quirks.
2. Within an album, keeps the highest-quality copy of each track (FLAC > MP3 > other) and removes the rest.
3. Across duplicate album directories for the same artist, keeps a "Deluxe Edition" copy over a standard one where both exist, otherwise keeps the first seen and removes the rest.
4. Removes resulting empty directories, skipping Synology `@eaDir` system folders.
5. Logs every action, with before/after file and folder counts, to a timestamped log file.

## Requirements

- `bash`
- A music library at a known path, structured as `Artist/Album/Track.ext`
- A writable log directory

## Configuration

Edit the path variables at the top of the script:

| Variable | Default | Description |
|---|---|---|
| `MUSIC_DIR` | `/music` | Root of the music library to deduplicate |
| `CONFIG_DIR` | `/config/logs` | Directory where timestamped run logs are written |

## Usage

### Standalone

```bash
chmod +x remove_duplicates.sh
MUSIC_DIR=/path/to/music CONFIG_DIR=/path/to/logs ./remove_duplicates.sh
```

(Set the variables directly in the script if your shell doesn't export them into it.)

### Inside a Beets Docker container

Run it against a running `linuxserver/beets` container that has your music volume mounted, either manually:

```bash
docker cp remove_duplicates.sh <container>:/config/remove_duplicates.sh
docker exec -it <container> bash /config/remove_duplicates.sh
```

or on a schedule by baking it into a custom image with a cron entry, e.g.:

```Dockerfile
FROM lscr.io/linuxserver/beets:latest
COPY remove_duplicates.sh /config/remove_duplicates.sh
RUN chmod +x /config/remove_duplicates.sh
RUN (crontab -l ; echo "0 3 * * * /config/remove_duplicates.sh") | crontab -
ENTRYPOINT ["cron", "-f"]
```

### Monitoring

```bash
ls "$CONFIG_DIR"
cat "$CONFIG_DIR"/remove_duplicates_*.log
```

## License

MIT — see [LICENSE](LICENSE).
