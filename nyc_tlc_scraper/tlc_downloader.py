import requests
import os
from datetime import datetime, timedelta
import calendar
from concurrent.futures import ThreadPoolExecutor, as_completed
from urllib.parse import urljoin
import time

class NYCTLCDownloader:
    def __init__(self, download_dir="nyc_tlc_data"):
        self.download_dir = download_dir
        self.base_url = "https://d37ci6vzurychx.cloudfront.net/trip-data/"
        
        # Data types available
        self.data_types = [
            "yellow_tripdata",
            "green_tripdata", 
            "fhv_tripdata",
            "fhvhv_tripdata"  # High Volume For-Hire Vehicle (Uber, Lyft, etc.)
        ]
        
        # Create download directory
        os.makedirs(download_dir, exist_ok=True)
        
    def generate_date_range(self, years_back=5):
        """Generate year-month combinations for the last N years"""
        end_date = datetime.now()
        start_date = end_date - timedelta(days=years_back * 365)
        
        dates = []
        current = start_date.replace(day=1)  # Start from first day of month
        
        while current <= end_date:
            dates.append((current.year, current.month))
            
            # Move to next month
            if current.month == 12:
                current = current.replace(year=current.year + 1, month=1)
            else:
                current = current.replace(month=current.month + 1)
                
        return dates

    def construct_download_url(self, data_type, year, month):
        """Construct download URL for a specific file"""
        filename = f"{data_type}_{year:04d}-{month:02d}.parquet"
        return urljoin(self.base_url, filename)

    def download_file(self, url, local_path, max_retries=3):
        """Download a single file with retry logic"""
        for attempt in range(max_retries):
            try:
                print(f"Downloading: {os.path.basename(local_path)} (Attempt {attempt + 1})")
                
                response = requests.get(url, stream=True, timeout=300)
                response.raise_for_status()
                
                # Check if file already exists and has same size
                if os.path.exists(local_path):
                    local_size = os.path.getsize(local_path)
                    remote_size = int(response.headers.get('content-length', 0))
                    if local_size == remote_size and local_size > 0:
                        print(f"File already exists: {os.path.basename(local_path)}")
                        return True
                
                # Download file
                with open(local_path, 'wb') as f:
                    for chunk in response.iter_content(chunk_size=8192):
                        if chunk:
                            f.write(chunk)
                
                print(f"Successfully downloaded: {os.path.basename(local_path)}")
                return True
                
            except requests.exceptions.RequestException as e:
                print(f"Error downloading {url}: {e}")
                if attempt == max_retries - 1:
                    print(f"Failed to download after {max_retries} attempts: {url}")
                    return False
                else:
                    time.sleep(2 ** attempt)  # Exponential backoff
        
        return False

    def download_data(self, data_types=None, years_back=5, max_workers=4):
        """Download TLC trip record data for specified data types and date range"""
        
        if data_types is None:
            data_types = self.data_types
        
        # Generate all file URLs to download
        download_tasks = []
        date_range = self.generate_date_range(years_back)
        
        for data_type in data_types:
            # Create subdirectory for each data type
            type_dir = os.path.join(self.download_dir, data_type)
            os.makedirs(type_dir, exist_ok=True)
            
            for year, month in date_range:
                url = self.construct_download_url(data_type, year, month)
                filename = f"{data_type}_{year:04d}-{month:02d}.parquet"
                local_path = os.path.join(type_dir, filename)
                
                download_tasks.append((url, local_path))
        
        print(f"Total files to download: {len(download_tasks)}")
        print(f"Data types: {data_types}")
        print(f"Date range: {min(date_range)} to {max(date_range)}")
        print(f"Download directory: {os.path.abspath(self.download_dir)}")
        print("-" * 50)
        
        # Download files using thread pool
        successful_downloads = 0
        failed_downloads = 0
        
        with ThreadPoolExecutor(max_workers=max_workers) as executor:
            # Submit all download tasks
            future_to_task = {
                executor.submit(self.download_file, url, path): (url, path) 
                for url, path in download_tasks
            }
            
            # Process completed downloads
            for future in as_completed(future_to_task):
                url, path = future_to_task[future]
                try:
                    success = future.result()
                    if success:
                        successful_downloads += 1
                    else:
                        failed_downloads += 1
                        print(f"Failed: {os.path.basename(path)}")
                        
                except Exception as e:
                    failed_downloads += 1
                    print(f"Exception downloading {os.path.basename(path)}: {e}")
        
        print("-" * 50)
        print(f"Download Summary:")
        print(f"Successful: {successful_downloads}")
        print(f"Failed: {failed_downloads}")
        print(f"Total: {len(download_tasks)}")
        
        return successful_downloads, failed_downloads

    def list_available_files(self):
        """List all downloaded files by category"""
        if not os.path.exists(self.download_dir):
            print("No download directory found.")
            return
        
        print(f"Files in {os.path.abspath(self.download_dir)}:")
        print("=" * 60)
        
        for data_type in self.data_types:
            type_dir = os.path.join(self.download_dir, data_type)
            if os.path.exists(type_dir):
                files = [f for f in os.listdir(type_dir) if f.endswith('.parquet')]
                files.sort()
                
                print(f"\n{data_type.upper()}:")
                print(f"  Count: {len(files)} files")
                if files:
                    total_size = sum(os.path.getsize(os.path.join(type_dir, f)) for f in files)
                    print(f"  Total size: {total_size / (1024**3):.2f} GB")
                    print(f"  Date range: {files[0][:19]} to {files[-1][:19]}")


# Example usage
if __name__ == "__main__":
    # Initialize downloader
    downloader = NYCTLCDownloader(download_dir="nyc_tlc_data")
    
    # Option 1: Download all data types for last 5 years
    print("Starting download of NYC TLC trip record data...")
    successful, failed = downloader.download_data(years_back=5, max_workers=4)
    
    # Option 2: Download specific data types only
    # successful, failed = downloader.download_data(
    #     data_types=["yellow_tripdata", "green_tripdata"], 
    #     years_back=3, 
    #     max_workers=2
    # )
    
    # List downloaded files
    print("\n")
    downloader.list_available_files()
    
    # Optional: Verify file integrity (basic check)
    print("\nVerifying downloaded files...")
    for data_type in downloader.data_types:
        type_dir = os.path.join(downloader.download_dir, data_type)
        if os.path.exists(type_dir):
            files = [f for f in os.listdir(type_dir) if f.endswith('.parquet')]
            corrupted = [f for f in files if os.path.getsize(os.path.join(type_dir, f)) < 1000]  # Files smaller than 1KB likely corrupted
            if corrupted:
                print(f"Potentially corrupted {data_type} files: {corrupted}")
            else:
                print(f"All {data_type} files appear valid ({len(files)} files)")