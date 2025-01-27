import requests

# Bitbucket credentials
username = "your_username"
password = "your_password"
workspace = "your_workspace"

# The string to search for
search_string = "your_search_string"

# Bitbucket API URL for listing repositories
repos_url = f"https://api.bitbucket.org/2.0/repositories/{workspace}"

# Function to search across all repositories and branches
def search_bitbucket_repos():
    try:
        # Fetch all repositories in the workspace
        response = requests.get(repos_url, auth=(username, password))
        response.raise_for_status()
        repositories = response.json()
        
        # Iterate through repositories
        for repo in repositories["values"]:
            repo_name = repo["slug"]
            print(f"Searching in repository: {repo_name}")
            
            # Fetch all branches for the repository
            branches_url = f"https://api.bitbucket.org/2.0/repositories/{workspace}/{repo_name}/refs/branches"
            branches_response = requests.get(branches_url, auth=(username, password))
            branches_response.raise_for_status()
            branches = branches_response.json()

            # Iterate through branches
            for branch in branches["values"]:
                branch_name = branch["name"]
                print(f"  Searching in branch: {branch_name}")
                
                # Fetch the branch content
                files_url = f"https://api.bitbucket.org/2.0/repositories/{workspace}/{repo_name}/src/{branch_name}"
                files_response = requests.get(files_url, auth=(username, password))
                files_response.raise_for_status()

                # Check if the search string is in the branch content
                if search_string in files_response.text:
                    print(f"  Found '{search_string}' in repository: {repo_name}, branch: {branch_name}")
                    break  # Stop searching further branches for this repo

    except requests.exceptions.RequestException as e:
        print(f"Error: {e}")

# Run the search
search_bitbucket_repos()