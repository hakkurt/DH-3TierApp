<?php
     
 try{
    // create a PostgreSQL database connection
    $myPDO = new PDO('pgsql:host=db-ip;dbname=dh', 'postgres', 'VMware1!');
 
    // display a message if connected to the PostgreSQL successfully
    if($myPDO){
        
    }
    }catch (PDOException $e){
    // report error message
    echo $e->getMessage();
	exit();
}
 
?>
<!DOCTYPE html>
<html>
<head>
	<title>DH NSX 3Tier App Demo</title>
	<link href="style.css" rel="stylesheet">
</head>
<body>

	<header class="header-6">
    <div class="branding">
        <a href="..." class="nav-link">
            <img src="cloud-48.png"> &emsp; <a href="index.php">
		<h3 style="color:white;">NSX 3 Tier Test Application</h3></a>
        </a>
    </div>
	<div class="header-nav">
        
            <img src="Nginx-logo.png" width=64> &emsp;
    </div>
	<div class="header-nav">
         
		<img src="apache.jpg" width=64> &emsp;
           
    </div>
		<div class="header-nav">
          
		<img src="php.png" width=64> &emsp;
           
    </div>
	 </div>
		<div class="header-nav">
          
		<img src="postgres.png" width=64> &emsp;
           
    </div>
	<div class="header-nav">
          
		<img src="docker.png" width=64> &emsp;
           
    </div>
	
    <div class="header-actions">
        <a href="https://www.linkedin.com/in/hakkurt/" class="nav-link nav-text">
            Developed by Dumlu & Hakan
        </a>
    </div>
</header>
	
	
	<div class="row flex-items-xs-top">
		<div class="col-xs">
			<div class="alert alert-app-level alert-info">
				<div class="alert-items">
					<div class="alert-item static">
						<div class="alert-text">
							Request is processed by  
							<?php 
							if($_SERVER[HTTP_HOST]=="Web01")
							echo "<span class='label label-info'>";
							else echo "<span class='label label-warning'>";
							echo $_SERVER[HTTP_HOST];
							echo "</span>";
							
							?>
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
							<form action="index.php" id="searchform" method="post" name="searchform">
								<label for="formFields_2">Name or Surname (Case Sensitive)</label> <input id="formFields_2" name="name" size="20" type="text"> <button class="btn btn-sm" name="submit" value="Search">Search</button>
							</form>
								<?php
									if(isset($_POST['submit'])){ 
										
										$name=$_POST['name']; 
										$results = $myPDO->query("SELECT * FROM actor WHERE  first_name LIKE '%" . $name . "%' OR last_name LIKE '%" . $name  ."%' order by actor_id  ");

									 } 
									else{ 
										$results = $myPDO->query("SELECT * FROM actor order by actor_id");
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
			</tr><?php endforeach; ?>
		</tbody>
	</table>
</body>
</html>