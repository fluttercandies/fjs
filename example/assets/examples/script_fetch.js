// Script Mode - Fetch API
// Using fetch (globally available)

fetch("https://api.github.com/users/github")
  .then(res => res.json())
  .then(data => ({
    name: data.name,
    followers: data.followers,
    public_repos: data.public_repos
  }))
