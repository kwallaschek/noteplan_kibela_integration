# noteplan_kibela_integration
A script that automatically uploads local notes to Kibela

# How to use

In `kibela_integration.rb` the following variables need to be set:
- TEAM (Your Kibela Team Name, team.kibe.la)
- TOKEN (Your personal Kibela Access Token. Can be generated under Profile>Settings. Needs read/write permissions.)
- GROUPID (The group id under which you are posting. Can be acquired via API calls at: {team}.kibe.la/api/console)
- NOTEPLAN_BASE_PATH (The base folder where your NotePlan App is saving its files.)
- KIBELA_BASE_PATH (The base folder path under which you are posting.)

Other Variables:
- FILE_CHANGE_CHECKING_RATE (The rate at which your local changes are pushed to Kibela. In seconds.)
- MAGIC_KEYWORD_FOR_PULLING (The magic word that, if found, triggers a pull from Kibela into your local note.)

## Run
```
$ bundle install
$ ruby kibela_integration.rb
```



### Query for GROUPIDs
```
query {
  groups (first:10){
    edges{
      node {
        name,
        id
      }
    }
  }
}
```

## Known Issues
- Currently, the script breaks when the path contains non-alphabetical characters like Kanji. The Problem occurs in the gem ‘Listen’ and is being posted as an issue on their Github. (This means the Folders in NotePlan also cannot contain these characters)