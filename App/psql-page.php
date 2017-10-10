<?php
/* paging_dinamis.php */
require_once "connection.inc.php";
echo "<form action=\"$PHP_SELF\" method=\"GET\">";
echo "<b>Number of Paging :</b>
<select name='batas'>
<option value='3'>3
<option value='5'>5
<option value='10'>10
<option value='10'>15
</select>&nbsp;";
echo "<input type=submit value='submit'>";
echo "</form>";
$flname=basename($PHP_SELF);
$res = mysql_query("SELECT * FROM table_name ORDER BY id");
$jml = @mysql_num_rows($res);
if ($jml == 0) {
echo "<font color=red>
<b>Ooops.... Data not found</b></font>";
exit;
}
// Initialization default value for paging
if (isset($_GET["batas"])) {
$batas = $_GET["batas"];
} else {
$batas = 3;
}
if (($jml % $batas) == 0) {
$jmlpage=(int)($jml/$batas);
} else {
$jmlpage=((int)$jml/$batas)+1;
}
// Inisialisasi variabel page
if (isset($_GET["page"])) {
$page = $_GET["page"];
} else {
$page = 1;
}
if ($page>$jmlpage) {
$page = $jmlpage;
}
while ($rows = mysql_fetch_array($res)) {
$arrdata[] = $rows;
}
$end = ($page*$batas)-1;
$start= $end-($batas-1);
if ($end > $jml) {
$end = $jml-1;
}
for ($i=$start; $i<=$end; $i++) {
$arr[] = $arrdata[$i];
}
echo "<table width=450 style='border:1pt solid #666666;'>";
foreach ($arr as $row) {
echo "<tr><td width=100>Nama</td>
<td width=10>:</td><td>$row[1]</td></tr>";
echo "<tr><td>Email</td><td>:</td><td>
<a href='mailtorow[2]'>$row[2]</a></td></tr>";
echo "<tr><td>Komentar</td>
<td>:</td><td>$row[3]</td></tr>";
echo "<tr><td>&nbsp;</td></tr>";
}
echo "</table> <br>";
// Manage paging navigation
for ($n=1; $n<=$jmlpage; $n++) {
$b = $page + 1;
if ($n != $page) {
echo "&nbsp;<a href='$flname?page=$n&batas=$batas'>
Hal $n</a>&nbsp;";
} else {
echo "<font color='#999999'><b>Hal $n </b></font>";
}
}
// Next navigation paging
if (($n != $page) && ($n > $b)) {
echo "&nbsp;<a href='$flname?page=$b&batas=$batas'>
Next</a>";
}
?>