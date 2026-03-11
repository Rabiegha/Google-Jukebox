#!/usr/bin/env python3
"""Delete all songs from Firestore and GCS bucket."""
import json
import subprocess
import urllib.parse
import ssl
import sys
import certifi

ssl_context = ssl.create_default_context(cafile=certifi.where())

BASE_URL = "https://firestore.googleapis.com/v1/projects/my-jukebox-app/databases/my-jukebox-app/documents"

def get_token():
    result = subprocess.run(["gcloud", "auth", "print-access-token"], capture_output=True, text=True)
    return result.stdout.strip()

def api_get(token, path):
    import urllib.request
    url = f"{BASE_URL}/{path}"
    req = urllib.request.Request(url, headers={"Authorization": f"Bearer {token}"})
    with urllib.request.urlopen(req, context=ssl_context) as resp:
        return json.loads(resp.read())

def api_delete(token, full_name):
    import urllib.request
    # URL-encode each path segment to handle spaces
    parts = full_name.split("/")
    encoded_parts = [urllib.parse.quote(p, safe='') for p in parts]
    encoded_name = "/".join(encoded_parts)
    url = f"https://firestore.googleapis.com/v1/{encoded_name}"
    req = urllib.request.Request(url, method="DELETE", headers={"Authorization": f"Bearer {token}"})
    try:
        with urllib.request.urlopen(req, context=ssl_context) as resp:
            return True
    except Exception as e:
        print(f"  ERROR deleting {full_name}: {e}")
        return False

def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else "list"
    token = get_token()
    
    # Get all genres
    data = api_get(token, "jukebox")
    genres = data.get("documents", [])
    print(f"Found {len(genres)} genres\n")
    
    total_songs = 0
    all_songs = []
    
    for genre_doc in genres:
        genre_name = genre_doc["name"].split("/")[-1]
        encoded = urllib.parse.quote(genre_name)
        
        try:
            songs_data = api_get(token, f"jukebox/{encoded}/musics")
            songs = songs_data.get("documents", [])
        except Exception:
            songs = []
        
        print(f"=== {genre_name}: {len(songs)} songs ===")
        for song in songs:
            fields = song.get("fields", {})
            title = fields.get("title", {}).get("stringValue", "N/A")
            song_id = song["name"].split("/")[-1]
            print(f"  {song_id}: {title}")
            all_songs.append(song["name"])
        total_songs += len(songs)
    
    print(f"\nTOTAL: {total_songs} songs")
    
    if mode == "delete":
        print(f"\n--- DELETING {total_songs} songs ---")
        deleted = 0
        for song_name in all_songs:
            if api_delete(token, song_name):
                deleted += 1
                print(f"  Deleted: {song_name.split('/')[-1]}")
        print(f"\nDeleted {deleted}/{total_songs} songs from Firestore")
    else:
        print("\nRun with 'delete' argument to actually delete: python3 cleanup_songs.py delete")

if __name__ == "__main__":
    main()
