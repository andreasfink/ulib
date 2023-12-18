//
//  UMCountryDigitTree.m
//  ulib
//
//  Created by Andreas Fink on 25.05.20.
//  Copyright © 2020 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/UMCountryDigitTree.h>

@implementation UMCountryDigitTree

- (UMCountryDigitTree *)init
{
    self = [super init];
    if(self)
    {
        [self setupCountries];
    }
    return self;
}

- (void)setupCountries
{
    [self addEntry:@"USA" forDigits:@"1"];
    [self addEntry:@"USA" forDigits:@"1201"];
    [self addEntry:@"USA" forDigits:@"1202"];
    [self addEntry:@"USA" forDigits:@"1203"];
    [self addEntry:@"CAN" forDigits:@"1204"];
    [self addEntry:@"USA" forDigits:@"1205"];
    [self addEntry:@"USA" forDigits:@"1206"];
    [self addEntry:@"USA" forDigits:@"1207"];
    [self addEntry:@"USA" forDigits:@"1208"];
    [self addEntry:@"USA" forDigits:@"1209"];
    [self addEntry:@"USA" forDigits:@"1210"];
    [self addEntry:@"USA" forDigits:@"1212"];
    [self addEntry:@"USA" forDigits:@"1213"];
    [self addEntry:@"USA" forDigits:@"1214"];
    [self addEntry:@"USA" forDigits:@"1215"];
    [self addEntry:@"USA" forDigits:@"1216"];
    [self addEntry:@"USA" forDigits:@"1217"];
    [self addEntry:@"USA" forDigits:@"1218"];
    [self addEntry:@"USA" forDigits:@"1219"];
    [self addEntry:@"USA" forDigits:@"1220"];
    [self addEntry:@"USA" forDigits:@"1223"];
    [self addEntry:@"USA" forDigits:@"1224"];
    [self addEntry:@"USA" forDigits:@"1225"];
    [self addEntry:@"CAN" forDigits:@"1226"];
    [self addEntry:@"USA" forDigits:@"1228"];
    [self addEntry:@"USA" forDigits:@"1229"];
    [self addEntry:@"USA" forDigits:@"1231"];
    [self addEntry:@"USA" forDigits:@"1234"];
    [self addEntry:@"CAN" forDigits:@"1236"];
    [self addEntry:@"USA" forDigits:@"1239"];
    [self addEntry:@"USA" forDigits:@"1240"];
    [self addEntry:@"BHS" forDigits:@"1242"];
    [self addEntry:@"BRB" forDigits:@"1246"];
    [self addEntry:@"USA" forDigits:@"1248"];
    [self addEntry:@"CAN" forDigits:@"1249"];
    [self addEntry:@"CAN" forDigits:@"1250"];
    [self addEntry:@"USA" forDigits:@"1251"];
    [self addEntry:@"USA" forDigits:@"1252"];
    [self addEntry:@"USA" forDigits:@"1253"];
    [self addEntry:@"USA" forDigits:@"1254"];
    [self addEntry:@"USA" forDigits:@"1256"];
    [self addEntry:@"USA" forDigits:@"1260"];
    [self addEntry:@"USA" forDigits:@"1262"];
    [self addEntry:@"AIA" forDigits:@"1264"];
    [self addEntry:@"USA" forDigits:@"1267"];
    [self addEntry:@"ATG" forDigits:@"1268"];
    [self addEntry:@"USA" forDigits:@"1270"];
    [self addEntry:@"USA" forDigits:@"1272"];
    [self addEntry:@"USA" forDigits:@"1276"];
    [self addEntry:@"USA" forDigits:@"1279"];
    [self addEntry:@"USA" forDigits:@"1281"];
    [self addEntry:@"VGB" forDigits:@"1284"];
    [self addEntry:@"CAN" forDigits:@"1289"];
    [self addEntry:@"USA" forDigits:@"1301"];
    [self addEntry:@"USA" forDigits:@"1304"];
    [self addEntry:@"USA" forDigits:@"1305"];
    [self addEntry:@"CAN" forDigits:@"1306"];
    [self addEntry:@"USA" forDigits:@"1307"];
    [self addEntry:@"USA" forDigits:@"1308"];
    [self addEntry:@"USA" forDigits:@"1309"];
    [self addEntry:@"USA" forDigits:@"1312"];
    [self addEntry:@"USA" forDigits:@"1313"];
    [self addEntry:@"USA" forDigits:@"1314"];
    [self addEntry:@"USA" forDigits:@"1315"];
    [self addEntry:@"USA" forDigits:@"1316"];
    [self addEntry:@"USA" forDigits:@"1317"];
    [self addEntry:@"USA" forDigits:@"1318"];
    [self addEntry:@"USA" forDigits:@"1319"];
    [self addEntry:@"USA" forDigits:@"1320"];
    [self addEntry:@"USA" forDigits:@"1321"];
    [self addEntry:@"USA" forDigits:@"1323"];
    [self addEntry:@"USA" forDigits:@"1325"];
    [self addEntry:@"USA" forDigits:@"1330"];
    [self addEntry:@"USA" forDigits:@"1331"];
    [self addEntry:@"USA" forDigits:@"1332"];
    [self addEntry:@"USA" forDigits:@"1334"];
    [self addEntry:@"USA" forDigits:@"1336"];
    [self addEntry:@"USA" forDigits:@"1337"];
    [self addEntry:@"USA" forDigits:@"1339"];
    [self addEntry:@"CAN" forDigits:@"1343"];
    [self addEntry:@"CYM" forDigits:@"1345"];
    [self addEntry:@"USA" forDigits:@"1346"];
    [self addEntry:@"USA" forDigits:@"1347"];
    [self addEntry:@"USA" forDigits:@"1351"];
    [self addEntry:@"USA" forDigits:@"1352"];
    [self addEntry:@"CAN" forDigits:@"1365"];
    [self addEntry:@"CAN" forDigits:@"1367"];
    [self addEntry:@"USA" forDigits:@"1380"];
    [self addEntry:@"USA" forDigits:@"1385"];
    [self addEntry:@"USA" forDigits:@"1386"];
    [self addEntry:@"USA" forDigits:@"1401"];
    [self addEntry:@"USA" forDigits:@"1402"];
    [self addEntry:@"CAN" forDigits:@"1403"];
    [self addEntry:@"USA" forDigits:@"1404"];
    [self addEntry:@"USA" forDigits:@"1405"];
    [self addEntry:@"USA" forDigits:@"1406"];
    [self addEntry:@"USA" forDigits:@"1407"];
    [self addEntry:@"USA" forDigits:@"1408"];
    [self addEntry:@"USA" forDigits:@"1409"];
    [self addEntry:@"USA" forDigits:@"1410"];
    [self addEntry:@"USA" forDigits:@"1412"];
    [self addEntry:@"USA" forDigits:@"1413"];
    [self addEntry:@"USA" forDigits:@"1414"];
    [self addEntry:@"USA" forDigits:@"1415"];
    [self addEntry:@"CAN" forDigits:@"1416"];
    [self addEntry:@"USA" forDigits:@"1417"];
    [self addEntry:@"CAN" forDigits:@"1418"];
    [self addEntry:@"USA" forDigits:@"1419"];
    [self addEntry:@"USA" forDigits:@"1423"];
    [self addEntry:@"USA" forDigits:@"1424"];
    [self addEntry:@"USA" forDigits:@"1425"];
    [self addEntry:@"CAN" forDigits:@"1428"];
    [self addEntry:@"USA" forDigits:@"1430"];
    [self addEntry:@"CAN" forDigits:@"1431"];
    [self addEntry:@"USA" forDigits:@"1432"];
    [self addEntry:@"USA" forDigits:@"1434"];
    [self addEntry:@"USA" forDigits:@"1435"];
    [self addEntry:@"CAN" forDigits:@"1437"];
    [self addEntry:@"CAN" forDigits:@"1438"];
    [self addEntry:@"USA" forDigits:@"1440"];
    [self addEntry:@"BMU" forDigits:@"1441"];
    [self addEntry:@"USA" forDigits:@"1442"];
    [self addEntry:@"USA" forDigits:@"1443"];
    [self addEntry:@"USA" forDigits:@"1445"];
    [self addEntry:@"CAN" forDigits:@"1450"];
    [self addEntry:@"USA" forDigits:@"1458"];
    [self addEntry:@"USA" forDigits:@"1463"];
    [self addEntry:@"USA" forDigits:@"1469"];
    [self addEntry:@"USA" forDigits:@"1470"];
    [self addEntry:@"USA" forDigits:@"1475"];
    [self addEntry:@"USA" forDigits:@"1478"];
    [self addEntry:@"USA" forDigits:@"1479"];
    [self addEntry:@"USA" forDigits:@"1480"];
    [self addEntry:@"USA" forDigits:@"1484"];
    [self addEntry:@"USA" forDigits:@"1501"];
    [self addEntry:@"USA" forDigits:@"1502"];
    [self addEntry:@"USA" forDigits:@"1503"];
    [self addEntry:@"USA" forDigits:@"1504"];
    [self addEntry:@"USA" forDigits:@"1505"];
    [self addEntry:@"CAN" forDigits:@"1506"];
    [self addEntry:@"USA" forDigits:@"1507"];
    [self addEntry:@"USA" forDigits:@"1508"];
    [self addEntry:@"USA" forDigits:@"1509"];
    [self addEntry:@"USA" forDigits:@"1510"];
    [self addEntry:@"USA" forDigits:@"1512"];
    [self addEntry:@"USA" forDigits:@"1513"];
    [self addEntry:@"CAN" forDigits:@"1514"];
    [self addEntry:@"USA" forDigits:@"1515"];
    [self addEntry:@"USA" forDigits:@"1516"];
    [self addEntry:@"USA" forDigits:@"1517"];
    [self addEntry:@"USA" forDigits:@"1518"];
    [self addEntry:@"CAN" forDigits:@"1519"];
    [self addEntry:@"USA" forDigits:@"1520"];
    [self addEntry:@"USA" forDigits:@"1530"];
    [self addEntry:@"USA" forDigits:@"1531"];
    [self addEntry:@"USA" forDigits:@"1534"];
    [self addEntry:@"USA" forDigits:@"1539"];
    [self addEntry:@"USA" forDigits:@"1540"];
    [self addEntry:@"USA" forDigits:@"1541"];
    [self addEntry:@"CAN" forDigits:@"1548"];
    [self addEntry:@"USA" forDigits:@"1551"];
    [self addEntry:@"USA" forDigits:@"1559"];
    [self addEntry:@"USA" forDigits:@"1561"];
    [self addEntry:@"USA" forDigits:@"1562"];
    [self addEntry:@"USA" forDigits:@"1563"];
    [self addEntry:@"USA" forDigits:@"1564"];
    [self addEntry:@"USA" forDigits:@"1567"];
    [self addEntry:@"USA" forDigits:@"1570"];
    [self addEntry:@"USA" forDigits:@"1571"];
    [self addEntry:@"USA" forDigits:@"1573"];
    [self addEntry:@"USA" forDigits:@"1574"];
    [self addEntry:@"USA" forDigits:@"1575"];
    [self addEntry:@"CAN" forDigits:@"1579"];
    [self addEntry:@"USA" forDigits:@"1580"];
    [self addEntry:@"CAN" forDigits:@"1581"];
    [self addEntry:@"USA" forDigits:@"1585"];
    [self addEntry:@"USA" forDigits:@"1586"];
    [self addEntry:@"CAN" forDigits:@"1587"];
    [self addEntry:@"USA" forDigits:@"1601"];
    [self addEntry:@"USA" forDigits:@"1602"];
    [self addEntry:@"USA" forDigits:@"1603"];
    [self addEntry:@"CAN" forDigits:@"1604"];
    [self addEntry:@"USA" forDigits:@"1605"];
    [self addEntry:@"USA" forDigits:@"1606"];
    [self addEntry:@"USA" forDigits:@"1607"];
    [self addEntry:@"USA" forDigits:@"1608"];
    [self addEntry:@"USA" forDigits:@"1609"];
    [self addEntry:@"USA" forDigits:@"1610"];
    [self addEntry:@"USA" forDigits:@"1612"];
    [self addEntry:@"CAN" forDigits:@"1613"];
    [self addEntry:@"USA" forDigits:@"1614"];
    [self addEntry:@"USA" forDigits:@"1615"];
    [self addEntry:@"USA" forDigits:@"1616"];
    [self addEntry:@"USA" forDigits:@"1617"];
    [self addEntry:@"USA" forDigits:@"1618"];
    [self addEntry:@"USA" forDigits:@"1619"];
    [self addEntry:@"USA" forDigits:@"1620"];
    [self addEntry:@"USA" forDigits:@"1623"];
    [self addEntry:@"USA" forDigits:@"1626"];
    [self addEntry:@"USA" forDigits:@"1628"];
    [self addEntry:@"USA" forDigits:@"1629"];
    [self addEntry:@"USA" forDigits:@"1630"];
    [self addEntry:@"USA" forDigits:@"1631"];
    [self addEntry:@"USA" forDigits:@"1636"];
    [self addEntry:@"CAN" forDigits:@"1639"];
    [self addEntry:@"USA" forDigits:@"1641"];
    [self addEntry:@"USA" forDigits:@"1646"];
    [self addEntry:@"CAN" forDigits:@"1647"];
    [self addEntry:@"USA" forDigits:@"1650"];
    [self addEntry:@"USA" forDigits:@"1651"];
    [self addEntry:@"USA" forDigits:@"1657"];
    [self addEntry:@"USA" forDigits:@"1660"];
    [self addEntry:@"USA" forDigits:@"1661"];
    [self addEntry:@"USA" forDigits:@"1662"];
    [self addEntry:@"USA" forDigits:@"1667"];
    [self addEntry:@"USA" forDigits:@"1669"];
    [self addEntry:@"USA" forDigits:@"1671"];
    [self addEntry:@"CAN" forDigits:@"1672"];
    [self addEntry:@"USA" forDigits:@"1678"];
    [self addEntry:@"USA" forDigits:@"1680"];
    [self addEntry:@"USA" forDigits:@"1681"];
    [self addEntry:@"USA" forDigits:@"1682"];
    [self addEntry:@"ASM" forDigits:@"1684"];
    [self addEntry:@"USA" forDigits:@"1701"];
    [self addEntry:@"USA" forDigits:@"1702"];
    [self addEntry:@"USA" forDigits:@"1703"];
    [self addEntry:@"USA" forDigits:@"1704"];
    [self addEntry:@"CAN" forDigits:@"1705"];
    [self addEntry:@"USA" forDigits:@"1706"];
    [self addEntry:@"USA" forDigits:@"1707"];
    [self addEntry:@"USA" forDigits:@"1708"];
    [self addEntry:@"CAN" forDigits:@"1709"];
    [self addEntry:@"USA" forDigits:@"1712"];
    [self addEntry:@"USA" forDigits:@"1713"];
    [self addEntry:@"USA" forDigits:@"1714"];
    [self addEntry:@"USA" forDigits:@"1715"];
    [self addEntry:@"USA" forDigits:@"1716"];
    [self addEntry:@"USA" forDigits:@"1717"];
    [self addEntry:@"USA" forDigits:@"1718"];
    [self addEntry:@"USA" forDigits:@"1719"];
    [self addEntry:@"USA" forDigits:@"1720"];
    [self addEntry:@"USA" forDigits:@"1724"];
    [self addEntry:@"USA" forDigits:@"1725"];
    [self addEntry:@"USA" forDigits:@"1726"];
    [self addEntry:@"USA" forDigits:@"1727"];
    [self addEntry:@"USA" forDigits:@"1731"];
    [self addEntry:@"USA" forDigits:@"1732"];
    [self addEntry:@"USA" forDigits:@"1734"];
    [self addEntry:@"USA" forDigits:@"1737"];
    [self addEntry:@"USA" forDigits:@"1740"];
    [self addEntry:@"USA" forDigits:@"1743"];
    [self addEntry:@"USA" forDigits:@"1747"];
    [self addEntry:@"USA" forDigits:@"1754"];
    [self addEntry:@"USA" forDigits:@"1757"];
    [self addEntry:@"USA" forDigits:@"1760"];
    [self addEntry:@"USA" forDigits:@"1762"];
    [self addEntry:@"USA" forDigits:@"1763"];
    [self addEntry:@"USA" forDigits:@"1765"];
    [self addEntry:@"USA" forDigits:@"1769"];
    [self addEntry:@"USA" forDigits:@"1770"];
    [self addEntry:@"USA" forDigits:@"1772"];
    [self addEntry:@"USA" forDigits:@"1773"];
    [self addEntry:@"USA" forDigits:@"1774"];
    [self addEntry:@"USA" forDigits:@"1775"];
    [self addEntry:@"CAN" forDigits:@"1778"];
    [self addEntry:@"USA" forDigits:@"1779"];
    [self addEntry:@"CAN" forDigits:@"1780"];
    [self addEntry:@"USA" forDigits:@"1781"];
    [self addEntry:@"CAN" forDigits:@"1782"];
    [self addEntry:@"USA" forDigits:@"1785"];
    [self addEntry:@"USA" forDigits:@"1786"];
    [self addEntry:@"USA" forDigits:@"1801"];
    [self addEntry:@"USA" forDigits:@"1802"];
    [self addEntry:@"USA" forDigits:@"1803"];
    [self addEntry:@"USA" forDigits:@"1804"];
    [self addEntry:@"USA" forDigits:@"1805"];
    [self addEntry:@"USA" forDigits:@"1806"];
    [self addEntry:@"CAN" forDigits:@"1807"];
    [self addEntry:@"USA" forDigits:@"1808"];
    [self addEntry:@"USA" forDigits:@"1810"];
    [self addEntry:@"USA" forDigits:@"1812"];
    [self addEntry:@"USA" forDigits:@"1813"];
    [self addEntry:@"USA" forDigits:@"1814"];
    [self addEntry:@"USA" forDigits:@"1815"];
    [self addEntry:@"USA" forDigits:@"1816"];
    [self addEntry:@"USA" forDigits:@"1817"];
    [self addEntry:@"USA" forDigits:@"1818"];
    [self addEntry:@"CAN" forDigits:@"1819"];
    [self addEntry:@"USA" forDigits:@"1820"];
    [self addEntry:@"CAN" forDigits:@"1825"];
    [self addEntry:@"USA" forDigits:@"1828"];
    [self addEntry:@"USA" forDigits:@"1830"];
    [self addEntry:@"USA" forDigits:@"1831"];
    [self addEntry:@"USA" forDigits:@"1832"];
    [self addEntry:@"USA" forDigits:@"1838"];
    [self addEntry:@"USA" forDigits:@"1843"];
    [self addEntry:@"USA" forDigits:@"1845"];
    [self addEntry:@"USA" forDigits:@"1847"];
    [self addEntry:@"USA" forDigits:@"1848"];
    [self addEntry:@"USA" forDigits:@"1850"];
    [self addEntry:@"USA" forDigits:@"1854"];
    [self addEntry:@"USA" forDigits:@"1856"];
    [self addEntry:@"USA" forDigits:@"1857"];
    [self addEntry:@"USA" forDigits:@"1858"];
    [self addEntry:@"USA" forDigits:@"1859"];
    [self addEntry:@"USA" forDigits:@"1860"];
    [self addEntry:@"USA" forDigits:@"1862"];
    [self addEntry:@"USA" forDigits:@"1863"];
    [self addEntry:@"USA" forDigits:@"1864"];
    [self addEntry:@"USA" forDigits:@"1865"];
    [self addEntry:@"CAN" forDigits:@"1867"];
    [self addEntry:@"USA" forDigits:@"1870"];
    [self addEntry:@"USA" forDigits:@"1872"];
    [self addEntry:@"CAN" forDigits:@"1873"];
    [self addEntry:@"USA" forDigits:@"1878"];
    [self addEntry:@"CAN" forDigits:@"1879"];
    [self addEntry:@"USA" forDigits:@"1901"];
    [self addEntry:@"CAN" forDigits:@"1902"];
    [self addEntry:@"USA" forDigits:@"1903"];
    [self addEntry:@"USA" forDigits:@"1904"];
    [self addEntry:@"CAN" forDigits:@"1905"];
    [self addEntry:@"USA" forDigits:@"1906"];
    [self addEntry:@"USA" forDigits:@"1907"];
    [self addEntry:@"USA" forDigits:@"1908"];
    [self addEntry:@"USA" forDigits:@"1909"];
    [self addEntry:@"USA" forDigits:@"1910"];
    [self addEntry:@"USA" forDigits:@"1912"];
    [self addEntry:@"USA" forDigits:@"1913"];
    [self addEntry:@"USA" forDigits:@"1914"];
    [self addEntry:@"USA" forDigits:@"1915"];
    [self addEntry:@"USA" forDigits:@"1916"];
    [self addEntry:@"USA" forDigits:@"1917"];
    [self addEntry:@"USA" forDigits:@"1918"];
    [self addEntry:@"USA" forDigits:@"1919"];
    [self addEntry:@"USA" forDigits:@"1920"];
    [self addEntry:@"USA" forDigits:@"1925"];
    [self addEntry:@"USA" forDigits:@"1928"];
    [self addEntry:@"USA" forDigits:@"1929"];
    [self addEntry:@"USA" forDigits:@"1930"];
    [self addEntry:@"USA" forDigits:@"1931"];
    [self addEntry:@"USA" forDigits:@"1934"];
    [self addEntry:@"USA" forDigits:@"1936"];
    [self addEntry:@"USA" forDigits:@"1937"];
    [self addEntry:@"USA" forDigits:@"1938"];
    [self addEntry:@"USA" forDigits:@"1940"];
    [self addEntry:@"USA" forDigits:@"1941"];
    [self addEntry:@"USA" forDigits:@"1947"];
    [self addEntry:@"USA" forDigits:@"1949"];
    [self addEntry:@"USA" forDigits:@"1951"];
    [self addEntry:@"USA" forDigits:@"1952"];
    [self addEntry:@"USA" forDigits:@"1954"];
    [self addEntry:@"USA" forDigits:@"1956"];
    [self addEntry:@"USA" forDigits:@"1959"];
    [self addEntry:@"USA" forDigits:@"1970"];
    [self addEntry:@"USA" forDigits:@"1971"];
    [self addEntry:@"USA" forDigits:@"1972"];
    [self addEntry:@"USA" forDigits:@"1973"];
    [self addEntry:@"USA" forDigits:@"1978"];
    [self addEntry:@"USA" forDigits:@"1979"];
    [self addEntry:@"USA" forDigits:@"1980"];
    [self addEntry:@"USA" forDigits:@"1984"];
    [self addEntry:@"USA" forDigits:@"1985"];
    [self addEntry:@"USA" forDigits:@"1986"];
    [self addEntry:@"USA" forDigits:@"1989"];
    [self addEntry:@"EGY" forDigits:@"20"];
    [self addEntry:@"SSD" forDigits:@"211"];
    [self addEntry:@"MAR" forDigits:@"212"];
    [self addEntry:@"DZA" forDigits:@"213"];
    [self addEntry:@"TUN" forDigits:@"216"];
    [self addEntry:@"LBY" forDigits:@"218"];
    [self addEntry:@"GMB" forDigits:@"220"];
    [self addEntry:@"SEN" forDigits:@"221"];
    [self addEntry:@"MRT" forDigits:@"222"];
    [self addEntry:@"MLI" forDigits:@"223"];
    [self addEntry:@"GIN" forDigits:@"224"];
    [self addEntry:@"CIV" forDigits:@"225"];
    [self addEntry:@"BFA" forDigits:@"226"];
    [self addEntry:@"NER" forDigits:@"227"];
    [self addEntry:@"TGO" forDigits:@"228"];
    [self addEntry:@"BEN" forDigits:@"229"];
    [self addEntry:@"MUS" forDigits:@"230"];
    [self addEntry:@"LBR" forDigits:@"231"];
    [self addEntry:@"SLE" forDigits:@"232"];
    [self addEntry:@"GHA" forDigits:@"233"];
    [self addEntry:@"NGA" forDigits:@"234"];
    [self addEntry:@"TCD" forDigits:@"235"];
    [self addEntry:@"CAF" forDigits:@"236"];
    [self addEntry:@"CMR" forDigits:@"237"];
    [self addEntry:@"CPV" forDigits:@"238"];
    [self addEntry:@"STP" forDigits:@"239"];
    [self addEntry:@"GNQ" forDigits:@"240"];
    [self addEntry:@"GAB" forDigits:@"241"];
    [self addEntry:@"COG" forDigits:@"242"];
    [self addEntry:@"COD" forDigits:@"243"];
    [self addEntry:@"AGO" forDigits:@"244"];
    [self addEntry:@"GNB" forDigits:@"245"];
    [self addEntry:@"IOT" forDigits:@"246"];
    [self addEntry:@"SYC" forDigits:@"248"];
    [self addEntry:@"SDN" forDigits:@"249"];
    [self addEntry:@"RWA" forDigits:@"250"];
    [self addEntry:@"ETH" forDigits:@"251"];
    [self addEntry:@"SOM" forDigits:@"252"];
    [self addEntry:@"DJI" forDigits:@"253"];
    [self addEntry:@"KEN" forDigits:@"254"];
    [self addEntry:@"TZA" forDigits:@"255"];
    [self addEntry:@"UGA" forDigits:@"256"];
    [self addEntry:@"BDI" forDigits:@"257"];
    [self addEntry:@"MOZ" forDigits:@"258"];
    [self addEntry:@"ZMB" forDigits:@"260"];
    [self addEntry:@"MDG" forDigits:@"261"];
    [self addEntry:@"MYT" forDigits:@"262"];
    [self addEntry:@"ZWE" forDigits:@"263"];
    [self addEntry:@"NAM" forDigits:@"264"];
    [self addEntry:@"MWI" forDigits:@"265"];
    [self addEntry:@"LSO" forDigits:@"266"];
    [self addEntry:@"BWA" forDigits:@"267"];
    [self addEntry:@"SWZ" forDigits:@"268"];
    [self addEntry:@"COM" forDigits:@"269"];
    [self addEntry:@"ZAF" forDigits:@"27"];
    [self addEntry:@"SHN" forDigits:@"290"];
    [self addEntry:@"ERI" forDigits:@"291"];
    [self addEntry:@"ABW" forDigits:@"297"];
    [self addEntry:@"FRO" forDigits:@"298"];
    [self addEntry:@"GRL" forDigits:@"299"];
    [self addEntry:@"GRC" forDigits:@"30"];
    [self addEntry:@"NLD" forDigits:@"31"];
    [self addEntry:@"BEL" forDigits:@"32"];
    [self addEntry:@"FRA" forDigits:@"33"];
    [self addEntry:@"ESP" forDigits:@"34"];
    [self addEntry:@"GIB" forDigits:@"350"];
    [self addEntry:@"PRT" forDigits:@"351"];
    [self addEntry:@"LUX" forDigits:@"352"];
    [self addEntry:@"IRL" forDigits:@"353"];
    [self addEntry:@"ISL" forDigits:@"354"];
    [self addEntry:@"ALB" forDigits:@"355"];
    [self addEntry:@"MLT" forDigits:@"356"];
    [self addEntry:@"CYP" forDigits:@"357"];
    [self addEntry:@"FIN" forDigits:@"358"];
    [self addEntry:@"BGR" forDigits:@"359"];
    [self addEntry:@"HUN" forDigits:@"36"];
    [self addEntry:@"LTU" forDigits:@"370"];
    [self addEntry:@"LVA" forDigits:@"371"];
    [self addEntry:@"EST" forDigits:@"372"];
    [self addEntry:@"MDA" forDigits:@"373"];
    [self addEntry:@"ARM" forDigits:@"374"];
    [self addEntry:@"BLR" forDigits:@"375"];
    [self addEntry:@"AND" forDigits:@"376"];
    [self addEntry:@"MCO" forDigits:@"377"];
    [self addEntry:@"SMR" forDigits:@"378"];
    [self addEntry:@"VAT" forDigits:@"379"];
    [self addEntry:@"UKR" forDigits:@"380"];
    [self addEntry:@"SRB" forDigits:@"381"];
    [self addEntry:@"MNE" forDigits:@"382"];
    [self addEntry:@"XKX" forDigits:@"383"];
    [self addEntry:@"HRV" forDigits:@"385"];
    [self addEntry:@"SVN" forDigits:@"386"];
    [self addEntry:@"BIH" forDigits:@"387"];
    [self addEntry:@"MKD" forDigits:@"389"];
    [self addEntry:@"ITA" forDigits:@"39"];
    [self addEntry:@"ROU" forDigits:@"40"];
    [self addEntry:@"CHE" forDigits:@"41"];
    [self addEntry:@"CZE" forDigits:@"420"];
    [self addEntry:@"SVK" forDigits:@"421"];
    [self addEntry:@"LIE" forDigits:@"423"];
    [self addEntry:@"AUT" forDigits:@"43"];
    [self addEntry:@"GBR" forDigits:@"44"];
    [self addEntry:@"GGY" forDigits:@"44-1481"];
    [self addEntry:@"JEY" forDigits:@"441534"];
    [self addEntry:@"IMN" forDigits:@"441624"];
    [self addEntry:@"DNK" forDigits:@"45"];
    [self addEntry:@"SWE" forDigits:@"46"];
    [self addEntry:@"NOR" forDigits:@"47"];
    [self addEntry:@"POL" forDigits:@"48"];
    [self addEntry:@"DEU" forDigits:@"49"];
    [self addEntry:@"FLK" forDigits:@"500"];
    [self addEntry:@"BLZ" forDigits:@"501"];
    [self addEntry:@"GTM" forDigits:@"502"];
    [self addEntry:@"SLV" forDigits:@"503"];
    [self addEntry:@"HND" forDigits:@"504"];
    [self addEntry:@"NIC" forDigits:@"505"];
    [self addEntry:@"CRI" forDigits:@"506"];
    [self addEntry:@"PAN" forDigits:@"507"];
    [self addEntry:@"SPM" forDigits:@"508"];
    [self addEntry:@"HTI" forDigits:@"509"];
    [self addEntry:@"PER" forDigits:@"51"];
    [self addEntry:@"MEX" forDigits:@"52"];
    [self addEntry:@"CUB" forDigits:@"53"];
    [self addEntry:@"ARG" forDigits:@"54"];
    [self addEntry:@"BRA" forDigits:@"55"];
    [self addEntry:@"CHL" forDigits:@"56"];
    [self addEntry:@"COL" forDigits:@"57"];
    [self addEntry:@"VEN" forDigits:@"58"];
    [self addEntry:@"BLM" forDigits:@"590"];
    [self addEntry:@"BOL" forDigits:@"591"];
    [self addEntry:@"GUY" forDigits:@"592"];
    [self addEntry:@"ECU" forDigits:@"593"];
    [self addEntry:@"PRY" forDigits:@"595"];
    [self addEntry:@"SUR" forDigits:@"597"];
    [self addEntry:@"URY" forDigits:@"598"];
    [self addEntry:@"ANT" forDigits:@"599"];
    [self addEntry:@"MYS" forDigits:@"60"];
    [self addEntry:@"AUS" forDigits:@"61"];
    [self addEntry:@"IDN" forDigits:@"62"];
    [self addEntry:@"PHL" forDigits:@"63"];
    [self addEntry:@"NZL" forDigits:@"64"];
    [self addEntry:@"SGP" forDigits:@"65"];
    [self addEntry:@"THA" forDigits:@"66"];
    [self addEntry:@"TLS" forDigits:@"670"];
    [self addEntry:@"ATA" forDigits:@"672"];
    [self addEntry:@"BRN" forDigits:@"673"];
    [self addEntry:@"NRU" forDigits:@"674"];
    [self addEntry:@"PNG" forDigits:@"675"];
    [self addEntry:@"TON" forDigits:@"676"];
    [self addEntry:@"SLB" forDigits:@"677"];
    [self addEntry:@"VUT" forDigits:@"678"];
    [self addEntry:@"FJI" forDigits:@"679"];
    [self addEntry:@"PLW" forDigits:@"680"];
    [self addEntry:@"WLF" forDigits:@"681"];
    [self addEntry:@"COK" forDigits:@"682"];
    [self addEntry:@"NIU" forDigits:@"683"];
    [self addEntry:@"WSM" forDigits:@"685"];
    [self addEntry:@"KIR" forDigits:@"686"];
    [self addEntry:@"NCL" forDigits:@"687"];
    [self addEntry:@"TUV" forDigits:@"688"];
    [self addEntry:@"PYF" forDigits:@"689"];
    [self addEntry:@"TKL" forDigits:@"690"];
    [self addEntry:@"FSM" forDigits:@"691"];
    [self addEntry:@"MHL" forDigits:@"692"];
    [self addEntry:@"KAZ" forDigits:@"7"];
    [self addEntry:@"JPN" forDigits:@"81"];
    [self addEntry:@"KOR" forDigits:@"82"];
    [self addEntry:@"VNM" forDigits:@"84"];
    [self addEntry:@"PRK" forDigits:@"850"];
    [self addEntry:@"HKG" forDigits:@"852"];
    [self addEntry:@"MAC" forDigits:@"853"];
    [self addEntry:@"KHM" forDigits:@"855"];
    [self addEntry:@"LAO" forDigits:@"856"];
    [self addEntry:@"CHN" forDigits:@"86"];
    [self addEntry:@"BGD" forDigits:@"880"];
    [self addEntry:@"TWN" forDigits:@"886"];
    [self addEntry:@"TUR" forDigits:@"90"];
    [self addEntry:@"IND" forDigits:@"91"];
    [self addEntry:@"PAK" forDigits:@"92"];
    [self addEntry:@"AFG" forDigits:@"93"];
    [self addEntry:@"LKA" forDigits:@"94"];
    [self addEntry:@"MMR" forDigits:@"95"];
    [self addEntry:@"MDV" forDigits:@"960"];
    [self addEntry:@"LBN" forDigits:@"961"];
    [self addEntry:@"JOR" forDigits:@"962"];
    [self addEntry:@"SYR" forDigits:@"963"];
    [self addEntry:@"IRQ" forDigits:@"964"];
    [self addEntry:@"KWT" forDigits:@"965"];
    [self addEntry:@"SAU" forDigits:@"966"];
    [self addEntry:@"YEM" forDigits:@"967"];
    [self addEntry:@"OMN" forDigits:@"968"];
    [self addEntry:@"PSE" forDigits:@"970"];
    [self addEntry:@"ARE" forDigits:@"971"];
    [self addEntry:@"ISR" forDigits:@"972"];
    [self addEntry:@"BHR" forDigits:@"973"];
    [self addEntry:@"QAT" forDigits:@"974"];
    [self addEntry:@"BTN" forDigits:@"975"];
    [self addEntry:@"MNG" forDigits:@"976"];
    [self addEntry:@"NPL" forDigits:@"977"];
    [self addEntry:@"IRN" forDigits:@"98"];
    [self addEntry:@"TJK" forDigits:@"992"];
    [self addEntry:@"TKM" forDigits:@"993"];
    [self addEntry:@"AZE" forDigits:@"994"];
    [self addEntry:@"GEO" forDigits:@"995"];
    [self addEntry:@"KGZ" forDigits:@"996"];
    [self addEntry:@"UZB" forDigits:@"998"];
}

@end