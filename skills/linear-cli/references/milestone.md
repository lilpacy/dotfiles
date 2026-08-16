# milestone

> Manage Linear project milestones

## Usage

```
Usage:   linear milestone
Version: 2.5.0           

Description:

  Manage Linear project milestones

Options:

  -h, --help           - Show this help.                      
  --workspace  <slug>  - Target workspace (uses credentials)  

Commands:

  list                  - List milestones for a project                                                 
  view, v  <milestone>  - View milestone details. By default lists the first 10 attached issues from the
                          first page of 50; use --all to paginate the full set.                         
  create                - Create a new project milestone                                                
  update   <id>         - Update an existing project milestone                                          
  delete   <id>         - Delete a project milestone
```

## Subcommands

### list

> List milestones for a project

```
Usage:   linear milestone list --project <project>
Version: 2.5.0                                    

Description:

  List milestones for a project

Options:

  -h, --help              - Show this help.                                
  --workspace  <slug>     - Target workspace (uses credentials)            
  --project    <project>  - Project (UUID, slug ID, or name)     (required)
```

### view

> View milestone details. By default lists the first 10 attached issues from the
> first page of 50; use --all to paginate the full set.

```
Usage:   linear milestone view <milestone>
Version: 2.5.0                            

Description:

  View milestone details. By default lists the first 10 attached issues from the first page of 50; use --all to paginate the full set.

Options:

  -h, --help              - Show this help.                                                                   
  --workspace  <slug>     - Target workspace (uses credentials)                                               
  --all                   - Fetch and list every issue attached to the milestone (paginates the Linear API).  
  --project    <project>  - Project for resolving a milestone name (UUID, slug ID, or name)
```

### create

> Create a new project milestone

```
Usage:   linear milestone create --project <project> --name <name>
Version: 2.5.0                                                    

Description:

  Create a new project milestone

Options:

  -h, --help                    - Show this help.                                
  --workspace    <slug>         - Target workspace (uses credentials)            
  --project      <project>      - Project (UUID, slug ID, or name)     (required)
  --name         <name>         - Milestone name                       (required)
  --description  <description>  - Milestone description                          
  --target-date  <date>         - Target date (YYYY-MM-DD)
```

### update

> Update an existing project milestone

```
Usage:   linear milestone update <id>
Version: 2.5.0                       

Description:

  Update an existing project milestone

Options:

  -h, --help                    - Show this help.                                       
  --workspace    <slug>         - Target workspace (uses credentials)                   
  --name         <name>         - Milestone name                                        
  --description  <description>  - Milestone description                                 
  --target-date  <date>         - Target date (YYYY-MM-DD)                              
  --sort-order   <value>        - Sort order relative to other milestones               
  --project      <project>      - Move to a different project (UUID, slug ID, or name)
```

### delete

> Delete a project milestone

```
Usage:   linear milestone delete <id>
Version: 2.5.0                       

Description:

  Delete a project milestone

Options:

  -h, --help           - Show this help.                      
  --workspace  <slug>  - Target workspace (uses credentials)  
  -f, --force          - Skip confirmation prompt
```
