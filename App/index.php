<?php
    $myPDO = new PDO('pgsql:host=db-ip;dbname=dh', 'postgres', 'VMware1!');

    
?>

  <!DOCTYPE html>
<html>
    <head>
        <title>DH NSX 3Tier App Demo</title>
        <link rel="stylesheet" href="style.css">
    </head>
    <body>
	

	 <div class="header">
		 <img src="cloud-48.png"> &emsp; <a href=index.php><H3 style="color:white;"> NSX Test Application</H3></a>
	  </div>
		<div class="row flex-items-xs-top">
		<div class="col-xs">
				<div class="alert alert-app-level alert-info">
					<div class="alert-items">
						<div class="alert-item static">
						
						<div class="alert-text">
							Request is coming from <?php echo $_SERVER[SERVER_NAME] ?>
						</div>
						</div>
					</div>
				</div>
		</div>
		</div>
		<div class="row flex-items-xs-top">
			<div class="col-xs">
				<div class="alert alert-app-level alert-danger">
					<div class="alert-items">
						<div class="alert-item static">
							
							<div class="alert-text">
							 <form  method="post" action="index.php"  id="searchform"> 
								<label for="formFields_2">Name or Surname (Case Sensitive)</label>
								<input id="formFields_2" size="20" type="text" name="name" >
								<button class="btn btn-sm" name="submit" value="Search">Search</button> 
								</form> 
								<?php
								if(isset($_POST['submit'])){ 
									
									$name=$_POST['name']; 
									$results = $myPDO->query("SELECT * FROM actor WHERE  first_name LIKE '%" . $name . "%' OR last_name LIKE '%" . $name  ."%' order by actor_id  LIMIT 20 ");

 								 } 
								else{ 
									$results = $myPDO->query("SELECT * FROM actor order by actor_id LIMIT 20 ");
								 } 
								  ?>
								  
								  
								  
								  
							</div>
						</div>
					</div>
				</div>
			</div>
		</div>

        <table class="table">
            <thead>
                <tr>
                    <th class="left">ID</th>
                    <th class="left">Name</th>
                    <th class="left">Surname</th>
                </tr>
            </thead>
            <tbody>
			
			<?php foreach ($results as $result) : ?>
                        <tr>
                            <td class="left"><?php echo htmlspecialchars($result['actor_id']) ?></td>
                            <td class="left"><?php echo htmlspecialchars($result['first_name']); ?></td>
                            <td class="left"><?php echo htmlspecialchars($result['last_name']); ?></td>
                        </tr>
            <?php endforeach; ?>
                
            </tbody>
        </table>

    </body>
</html>
	

