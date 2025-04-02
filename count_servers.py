#!/usr/bin/env python3
"""
Script to count and rank the top 20 email servers from email_servers.csv
Outputs results to the console and to a CSV file
"""
from collections import Counter
import csv
import os

# Path to the email_servers.csv file
file_path = os.path.join(os.getcwd(), 'email_servers.csv')
output_path = os.path.join(os.getcwd(), 'server_rankings.csv')

# Initialize a counter
server_counter = Counter()

# Read the CSV file and count occurrences of each server
with open(file_path, 'r') as file:
    for line in file:
        server = line.strip()
        if server:  # Skip empty lines
            server_counter[server] += 1

# Get the top 20 most common servers
top_20 = server_counter.most_common(20)

# Print the results in a formatted table
print(f"\n{'Rank':<6}{'Server':<60}{'Count':<10}")
print("-" * 76)

for rank, (server, count) in enumerate(top_20, 1):
    print(f"{rank:<6}{server:<60}{count:<10}")

print(f"\nTotal unique servers: {len(server_counter)}")
print(f"Total server entries: {sum(server_counter.values())}")

# Save results to CSV file
with open(output_path, 'w', newline='') as csvfile:
    writer = csv.writer(csvfile)
    writer.writerow(['Rank', 'Server', 'Count'])
    for rank, (server, count) in enumerate(top_20, 1):
        writer.writerow([rank, server, count])
    
    # Add summary information
    writer.writerow([])
    writer.writerow(['Total unique servers', len(server_counter)])
    writer.writerow(['Total server entries', sum(server_counter.values())])

print(f"\nResults saved to {output_path}")