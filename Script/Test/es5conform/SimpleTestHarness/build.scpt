FasdUAS 1.101.10   ��   ��    k             l      ��  ��    � �
	OS X ECMAScript 5 Conformance Test Suite Generator
	
	Run from Terminal by : osascript build.scpt	- Accepted Arguments
		- /dynamic		- /toplevel 
		
	Brian Antonelli <brian.antonelli@gmail.com>     � 	 	� 
 	 O S   X   E C M A S c r i p t   5   C o n f o r m a n c e   T e s t   S u i t e   G e n e r a t o r 
 	 
 	 R u n   f r o m   T e r m i n a l   b y   :   o s a s c r i p t   b u i l d . s c p t  	 -   A c c e p t e d   A r g u m e n t s 
 	 	 -   / d y n a m i c  	 	 -   / t o p l e v e l   
 	 	 
 	 B r i a n   A n t o n e l l i   < b r i a n . a n t o n e l l i @ g m a i l . c o m >    
  
 l     ��������  ��  ��        p         �� �� 0 scriptz    �� �� 0 toplevel topLevel  ������  0 statictestload staticTestLoad��        l     ��������  ��  ��        l     ��  ��      our main()     �      o u r   m a i n ( )      i         I     �� ��
�� .aevtoappnull  �   � ****  o      ���� 0 argv  ��    k    #       Q        ! "   r     # $ # l    %���� % n     & ' & 1    ��
�� 
leng ' o    ���� 0 argv  ��  ��   $ o      ���� 0 foo   ! R      ������
�� .ascrerr ****      � ****��  ��   " l    ( ) * ( r     + , + J    ����   , o      ���� 0 argv   ) ) # for running from the script editor    * � - - F   f o r   r u n n i n g   f r o m   t h e   s c r i p t   e d i t o r   . / . l   ��������  ��  ��   /  0 1 0 l   �� 2 3��   2   get our current path    3 � 4 4 *   g e t   o u r   c u r r e n t   p a t h 1  5 6 5 O   " 7 8 7 e    ! 9 9 n    ! : ; : m     ��
�� 
cfol ; l    <���� < I   �� =��
�� .earsffdralis        afdr =  f    ��  ��  ��   8 m     > >�                                                                                  MACS   alis    r  Macintosh HD               ��]H+     t
Finder.app                                                       u$ò��        ����  	                CoreServices    ��R�      ó3"       t   0   /  3Macintosh HD:System:Library:CoreServices:Finder.app    
 F i n d e r . a p p    M a c i n t o s h   H D  &System/Library/CoreServices/Finder.app  / ��   6  ? @ ? r   # & A B A 1   # $��
�� 
rslt B o      ���� 0 myfolder myFolder @  C D C l  ' '�� E F��   E   get our current folder    F � G G .   g e t   o u r   c u r r e n t   f o l d e r D  H I H O  ' 1 J K J e   + 0 L L c   + 0 M N M n   + . O P O m   , .��
�� 
ctnr P l  + , Q���� Q o   + ,���� 0 myfolder myFolder��  ��   N m   . /��
�� 
utxt K m   ' ( R R�                                                                                  MACS   alis    r  Macintosh HD               ��]H+     t
Finder.app                                                       u$ò��        ����  	                CoreServices    ��R�      ó3"       t   0   /  3Macintosh HD:System:Library:CoreServices:Finder.app    
 F i n d e r . a p p    M a c i n t o s h   H D  &System/Library/CoreServices/Finder.app  / ��   I  S T S r   2 5 U V U 1   2 3��
�� 
rslt V o      ���� 0 
mainfolder 
mainFolder T  W X W l  6 6�� Y Z��   Y    get the test cases folder    Z � [ [ 4   g e t   t h e   t e s t   c a s e s   f o l d e r X  \ ] \ r   6 ; ^ _ ^ b   6 9 ` a ` o   6 7���� 0 
mainfolder 
mainFolder a m   7 8 b b � c c  T e s t C a s e s : _ o      ����  0 startingfolder startingFolder ]  d e d r   < ? f g f m   < =��
�� boovfals g o      ���� 0 toplevel topLevel e  h i h r   @ C j k j m   @ A��
�� boovtrue k o      ����  0 statictestload staticTestLoad i  l m l r   D J n o n J   D F����   o o      ���� 0 scriptz   m  p q p l  K K��������  ��  ��   q  r s r l  K K�� t u��   t ( " check for user provided arguments    u � v v D   c h e c k   f o r   u s e r   p r o v i d e d   a r g u m e n t s s  w x w Y   K � y�� z {�� y Z   X  | } ~�� | l  X b ����  =  X b � � � n   X ^ � � � 4   Y ^�� �
�� 
cobj � o   \ ]���� 0 i   � o   X Y���� 0 argv   � m   ^ a � � � � �  / t o p l e v e l��  ��   } r   e h � � � m   e f��
�� boovtrue � o      ���� 0 toplevel topLevel ~  � � � l  k u ����� � =  k u � � � n   k q � � � 4   l q�� �
�� 
cobj � o   o p���� 0 i   � o   k l���� 0 argv   � m   q t � � � � �  / d y n a m i c��  ��   �  ��� � r   x { � � � m   x y��
�� boovfals � o      ����  0 statictestload staticTestLoad��  ��  �� 0 i   z m   N O����  { l  O S ����� � n   O S � � � 1   P R��
�� 
leng � o   O P���� 0 argv  ��  ��  ��   x  � � � l  � ���������  ��  ��   �  � � � l  � ��� � ���   � 8 2 determine whether to do a test group or test case    � � � � d   d e t e r m i n e   w h e t h e r   t o   d o   a   t e s t   g r o u p   o r   t e s t   c a s e �  � � � O   � � � � � Z   � � � ��� � � l  � � ����� � I  � ��� ���
�� .coredoexbool       obj  � 4   � ��� �
�� 
cfol � o   � �����  0 startingfolder startingFolder��  ��  ��   � n  � � � � � I   � ��� ����� 0 
find_tests   �  ��� � o   � �����  0 startingfolder startingFolder��  ��   �  f   � ���   � n  � � � � � I   � ��� ����� 0 add_test   �  ��� � o   � �����  0 startingfolder startingFolder��  ��   �  f   � � � m   � � � ��                                                                                  MACS   alis    r  Macintosh HD               ��]H+     t
Finder.app                                                       u$ò��        ����  	                CoreServices    ��R�      ó3"       t   0   /  3Macintosh HD:System:Library:CoreServices:Finder.app    
 F i n d e r . a p p    M a c i n t o s h   H D  &System/Library/CoreServices/Finder.app  / ��   �  � � � l  � ���������  ��  ��   �  � � � l  � ��� � ���   � ' ! open the output file for writing    � � � � B   o p e n   t h e   o u t p u t   f i l e   f o r   w r i t i n g �  � � � Q   � � � � � k   � � � �  � � � r   � � � � � l  � � ����� � b   � � � � � l  � � ����� � c   � � � � � o   � ����� 0 myfolder myFolder � m   � ���
�� 
TEXT��  ��   � m   � � � � � � �  t e s t . h t m l��  ��   � o      ���� 0 target_file_path   �  � � � r   � � � � � I  � ��� � �
�� .rdwropenshor       file � l  � � ����� � 4   � ��� �
�� 
file � o   � ����� 0 target_file_path  ��  ��   � �� ���
�� 
perm � m   � ���
�� boovtrue��   � o      ���� 	0 phile   �  � � � l  � ��� � ���   � "  overwrite the previous file    � � � � 8   o v e r w r i t e   t h e   p r e v i o u s   f i l e �  � � � I  � ��� � �
�� .rdwrseofnull���     **** � l  � � ����� � o   � ����� 	0 phile  ��  ��   � �� ���
�� 
set2 � m   � �����  ��   �  � � � l  � �� � ��   �   write down to the file    � � � � .   w r i t e   d o w n   t o   t h e   f i l e �  � � � I   � ��~ ��}�~ 0 write_header   �  ��| � o   � ��{�{ 	0 phile  �|  �}   �  � � � I   � ��z ��y�z 0 write_content   �  ��x � o   � ��w�w 	0 phile  �x  �y   �  � � � I   � ��v ��u�v 0 write_footer   �  ��t � o   � ��s�s 	0 phile  �t  �u   �  ��r � I  � ��q ��p
�q .rdwrclosnull���     **** � l  � � ��o�n � o   � ��m�m 	0 phile  �o  �n  �p  �r   � R      �l�k�j
�l .ascrerr ****      � ****�k  �j   � Q   � ��i � I �h ��g
�h .rdwrclosnull���     **** � l  ��f�e � o  �d�d 	0 phile  �f  �e  �g   � R      �c�b�a
�c .ascrerr ****      � ****�b  �a  �i   �  � � � l �`�_�^�`  �_  �^   �  � � � l �] � ��]   � W Q this will allow you to choose which app to test with (only works if run via gui)    � � � � �   t h i s   w i l l   a l l o w   y o u   t o   c h o o s e   w h i c h   a p p   t o   t e s t   w i t h   ( o n l y   w o r k s   i f   r u n   v i a   g u i ) �  �  � l �\�\   � ~set theApp to choose application with title "Installed Applications" with prompt "Select an application to test with" as alias    � � s e t   t h e A p p   t o   c h o o s e   a p p l i c a t i o n   w i t h   t i t l e   " I n s t a l l e d   A p p l i c a t i o n s "   w i t h   p r o m p t   " S e l e c t   a n   a p p l i c a t i o n   t o   t e s t   w i t h "   a s   a l i a s   l �[�Z�Y�[  �Z  �Y    l �X	�X   F @ open the test file with the system's default registered program   	 �

 �   o p e n   t h e   t e s t   f i l e   w i t h   t h e   s y s t e m ' s   d e f a u l t   r e g i s t e r e d   p r o g r a m  O  ! I  �W�V
�W .aevtodocnull  �    alis o  �U�U 0 target_file_path  �V   m  �                                                                                  MACS   alis    r  Macintosh HD               ��]H+     t
Finder.app                                                       u$ò��        ����  	                CoreServices    ��R�      ó3"       t   0   /  3Macintosh HD:System:Library:CoreServices:Finder.app    
 F i n d e r . a p p    M a c i n t o s h   H D  &System/Library/CoreServices/Finder.app  / ��   �T l ""�S�R�Q�S  �R  �Q  �T     l     �P�O�N�P  �O  �N    l     �M�L�K�M  �L  �K    l     �J�J   ( " recursively collects test scripts    � D   r e c u r s i v e l y   c o l l e c t s   t e s t   s c r i p t s  i     I      �I�H�I 0 
find_tests    �G  o      �F�F 	0 fpath  �G  �H   O     �!"! k    �## $%$ r    	&'& c    ()( o    �E�E 	0 fpath  ) m    �D
�D 
TEXT' o      �C�C 	0 fpath  % *+* l  
 
�B,-�B  , E ? get all of the items in the current folder (ignore invisibles)   - �.. ~   g e t   a l l   o f   t h e   i t e m s   i n   t h e   c u r r e n t   f o l d e r   ( i g n o r e   i n v i s i b l e s )+ /0/ r   
 121 I  
 �A34
�A .earslfdrutxt  @    file3 o   
 �@�@ 	0 fpath  4 �?5�>
�? 
lfiv5 m    �=
�= boovfals�>  2 o      �<�< 	0 itemz  0 676 r    898 J    �;�;  9 o      �:�: 0 
subfolders  7 :;: r    <=< m    �9
�9 boovfals= o      �8�8 0 	foundfile 	foundFile; >?> l   �7�6�5�7  �6  �5  ? @A@ X    UB�4CB k   - PDD EFE r   - 6GHG c   - 4IJI b   - 2KLK b   - 0MNM l  - .O�3�2O o   - .�1�1 	0 fpath  �3  �2  N o   . /�0�0 0 i  L m   0 1PP �QQ  :J m   2 3�/
�/ 
alisH o      �.�. 0 myitem myItemF RSR l  7 7�-TU�-  T F @ we want to process all of the files first, so queue the folders   U �VV �   w e   w a n t   t o   p r o c e s s   a l l   o f   t h e   f i l e s   f i r s t ,   s o   q u e u e   t h e   f o l d e r sS W�,W Z   7 PXY�+ZX l  7 <[�*�)[ =  7 <\]\ l  7 :^�(�'^ n   7 :_`_ 1   8 :�&
�& 
kind` o   7 8�%�% 0 myitem myItem�(  �'  ] m   : ;aa �bb  F o l d e r�*  �)  Y r   ? Ccdc o   ? @�$�$ 0 myitem myItemd n      efe  ;   A Bf o   @ A�#�# 0 
subfolders  �+  Z k   F Pgg hih l  F F�"jk�"  j   add the test   k �ll    a d d   t h e   t e s ti mnm n  F Lopo I   G L�!q� �! 0 add_test  q r�r o   G H�� 0 myitem myItem�  �   p  f   F Gn s�s r   M Ptut m   M N�
� boovtrueu o      �� 0 	foundfile 	foundFile�  �,  �4 0 i  C o     !�� 	0 itemz  A vwv l  V V����  �  �  w xyx l  V V�z{�  z D > if the folder contained any files then add a null dilemeter		   { �|| |   i f   t h e   f o l d e r   c o n t a i n e d   a n y   f i l e s   t h e n   a d d   a   n u l l   d i l e m e t e r 	 	y }~} Z   V d��� o   V W�� 0 	foundfile 	foundFile� n  Z `��� I   [ `���� 0 add_test  � ��� m   [ \�
� 
null�  �  �  f   Z [�  �  ~ ��� l  e e����  �  �  � ��� l  e e����  � 2 , now process all of the folders, recursively   � ��� X   n o w   p r o c e s s   a l l   o f   t h e   f o l d e r s ,   r e c u r s i v e l y� ��� X   e ���
�� n  u {��� I   v {�	���	 0 
find_tests  � ��� o   v w�� 0 i  �  �  �  f   u v�
 0 i  � o   h i�� 0 
subfolders  � ��� l  � �����  �  �  �  " m     ���                                                                                  MACS   alis    r  Macintosh HD               ��]H+     t
Finder.app                                                       u$ò��        ����  	                CoreServices    ��R�      ó3"       t   0   /  3Macintosh HD:System:Library:CoreServices:Finder.app    
 F i n d e r . a p p    M a c i n t o s h   H D  &System/Library/CoreServices/Finder.app  / ��   ��� l     � �����   ��  ��  � ��� l     ��������  ��  ��  � ��� l     ������  � ) # processes and stores a test script   � ��� F   p r o c e s s e s   a n d   s t o r e s   a   t e s t   s c r i p t� ��� i    ��� I      ������� 0 add_test  � ���� o      ���� 0 script_path  ��  ��  � k     V�� ��� l     ������  � H B only process the test if we aren't adding the null dilemeter test   � ��� �   o n l y   p r o c e s s   t h e   t e s t   i f   w e   a r e n ' t   a d d i n g   t h e   n u l l   d i l e m e t e r   t e s t� ��� Z     Q������� l    ������ >    ��� o     ���� 0 script_path  � m    ��
�� 
null��  ��  � k    M�� ��� l   ������  �   get the unixy path   � ��� &   g e t   t h e   u n i x y   p a t h� ��� r    ��� c    ��� n    	��� 1    	��
�� 
psxp� o    ���� 0 script_path  � m   	 
��
�� 
TEXT� o      ���� 0 script_path  � ��� l   ��������  ��  ��  � ��� l   ������  � + % check if we are relative or absolute   � ��� J   c h e c k   i f   w e   a r e   r e l a t i v e   o r   a b s o l u t e� ��� r    ��� I   �����
�� .sysooffslong    ��� null��  � ����
�� 
psof� m    �� ���  T e s t C a s e s /� �����
�� 
psin� o    ���� 0 script_path  ��  � o      ���� 0 base  � ��� r    ��� m    �� ���  � o      ���� 
0 prefix  � ��� Z    G������� l   !������ @    !��� o    ���� 0 base  � m     ����  ��  ��  � k   $ C�� ��� l  $ $������  � 3 - chomp everything before our TestCases folder   � ��� Z   c h o m p   e v e r y t h i n g   b e f o r e   o u r   T e s t C a s e s   f o l d e r� ��� r   $ 5��� c   $ 3��� n   $ 1��� 7 % 1����
�� 
cha � o   ) +���� 0 base  � l  , 0������ n   , 0��� 1   . 0��
�� 
leng� o   , .���� 0 script_path  ��  ��  � o   $ %���� 0 script_path  � m   1 2��
�� 
TEXT� o      ���� 0 script_path  � ��� l  6 6������  � V P if this is run from the SimpleTestHarness folder then we'll need to jump up one   � ��� �   i f   t h i s   i s   r u n   f r o m   t h e   S i m p l e T e s t H a r n e s s   f o l d e r   t h e n   w e ' l l   n e e d   t o   j u m p   u p   o n e� ���� Z   6 C������� l  6 9������ =  6 9��� o   6 7���� 0 toplevel topLevel� m   7 8��
�� boovfals��  ��  � r   < ?��� m   < =�� ���  . . /� o      ���� 
0 prefix  ��  ��  ��  ��  ��  �    l  H H����   , & generate our final path to the script    � L   g e n e r a t e   o u r   f i n a l   p a t h   t o   t h e   s c r i p t �� r   H M b   H K	 o   H I���� 
0 prefix  	 o   I J���� 0 script_path   o      ���� 0 script_path  ��  ��  ��  � 

 l  R R��������  ��  ��    l  R R����     store the script path    � ,   s t o r e   t h e   s c r i p t   p a t h �� r   R V l  R S���� o   R S���� 0 script_path  ��  ��   n        ;   T U o   S T���� 0 scriptz  ��  �  l     ��������  ��  ��    l     ��������  ��  ��    l     ����   ( " write the header to our test file    � D   w r i t e   t h e   h e a d e r   t o   o u r   t e s t   f i l e  !  i    "#" I      ��$���� 0 write_header  $ %��% o      ���� 	0 phile  ��  ��  # k     /&& '(' I    ��)*
�� .rdwrwritnull���     ****) m     ++ �,, � 
 < h t m l > 
 	 < h e a d > 
 	 	 < m e t a   h t t p - e q u i v = " X - U A - C o m p a t i b l e "   c o n t e n t = " I E = 8 " / > 
* ��-��
�� 
refn- o    ���� 	0 phile  ��  ( ./. l   ��������  ��  ��  / 010 r    232 m    	44 �55  3 o      ���� 
0 prefix  1 676 Z    89����8 l   :����: =   ;<; o    ���� 0 toplevel topLevel< m    ��
�� boovtrue��  ��  9 r    =>= m    ?? �@@ $ S i m p l e T e s t H a r n e s s /> o      ���� 
0 prefix  ��  ��  7 ABA I   %��CD
�� .rdwrwritnull���     ****C b    EFE b    GHG m    II �JJ L 	 	 < s c r i p t   t y p e = " t e x t / j a v a s c r i p t "   s r c = "H o    ���� 
0 prefix  F m    KK �LL " s t h . j s " > < / s c r i p t >D ��M��
�� 
refnM o     !���� 	0 phile  ��  B NON l  & &��������  ��  ��  O PQP I  & -��RS
�� .rdwrwritnull���     ****R m   & 'TT �UU � 
 	 	 < s c r i p t > v a r   E S 5 H a r n e s s   =   a c t i v e S t h ; < / s c r i p t > 
 	 < / h e a d > 
 	 < b o d y > 
 	 	 < s c r i p t > 
 	 	 	 v a r   a r y T e s t C a s e P a t h s   =   [ 
S ��V��
�� 
refnV o   ( )���� 	0 phile  ��  Q W��W l  . .��������  ��  ��  ��  ! XYX l     ��������  ��  ��  Y Z[Z l     ��������  ��  ��  [ \]\ l     ��^_��  ^    write the test references   _ �`` 4   w r i t e   t h e   t e s t   r e f e r e n c e s] aba i    cdc I      ��e���� 0 write_content  e f��f o      ���� 	0 phile  ��  ��  d Y     3g��hi��g Z    .jk�lj l   m�~�}m >   non n    pqp 4    �|r
�| 
cobjr o    �{�{ 0 i  q o    �z�z 0 scriptz  o m    �y
�y 
null�~  �}  k I   $�xst
�x .rdwrwritnull���     ****s b    uvu b    wxw m    yy �zz 
 	 	 	 	 "x l   {�w�v{ n    |}| 4    �u~
�u 
cobj~ o    �t�t 0 i  } o    �s�s 0 scriptz  �w  �v  v m     ���  " , 
t �r��q
�r 
refn� o     �p�p 	0 phile  �q  �  l I  ' .�o��
�o .rdwrwritnull���     ****� m   ' (�� ���  	 	 	 	 n u l l , 
� �n��m
�n 
refn� o   ) *�l�l 	0 phile  �m  �� 0 i  h m    �k�k i l   ��j�i� n    ��� 1    �h
�h 
leng� o    �g�g 0 scriptz  �j  �i  ��  b ��� l     �f�e�d�f  �e  �d  � ��� l     �c�b�a�c  �b  �a  � ��� l     �`���`  �   write the footer   � ��� "   w r i t e   t h e   f o o t e r� ��� i    ��� I      �_��^�_ 0 write_footer  � ��]� o      �\�\ 	0 phile  �]  �^  � k     �� ��� I    �[��
�[ .rdwrwritnull���     ****� m     �� ���  
 	 	 	 ] ;   
� �Z��Y
�Z 
refn� o    �X�X 	0 phile  �Y  � ��� l   �W�V�U�W  �V  �U  � ��� l   �T���T  � J D if they specified static test then don't include all of the scripts   � ��� �   i f   t h e y   s p e c i f i e d   s t a t i c   t e s t   t h e n   d o n ' t   i n c l u d e   a l l   o f   t h e   s c r i p t s� ��� Z    5���S�R� l   ��Q�P� >   ��� o    	�O�O  0 statictestload staticTestLoad� m   	 
�N
�N boovtrue�Q  �P  � k    1�� ��� r    ��� m    �� ���  " . "� o      �M�M 
0 prefix  � ��� Z    ���L�K� l   ��J�I� =   ��� o    �H�H 0 toplevel topLevel� m    �G
�G boovtrue�J  �I  � r    ��� m    �� ��� & " S i m p l e T e s t H a r n e s s "� o      �F�F 
0 prefix  �L  �K  � ��� I    '�E��
�E .rdwrwritnull���     ****� m     !�� ��� B 	 	 s h t _ l o a d t e s t s ( a r y T e s t C a s e P a t h s ,� �D��C
�D 
refn� o   " #�B�B 	0 phile  �C  � ��A� I  ( 1�@��
�@ .rdwrwritnull���     ****� b   ( +��� o   ( )�?�? 
0 prefix  � m   ) *�� ���  ) ;� �>��=
�> 
refn� o   , -�<�< 	0 phile  �=  �A  �S  �R  � ��� l  6 6�;�:�9�;  �:  �9  � ��� I  6 =�8��
�8 .rdwrwritnull���     ****� m   6 7�� ���  
 	 	 < / s c r i p t > 
� �7��6
�7 
refn� o   8 9�5�5 	0 phile  �6  � ��� l  > >�4�3�2�4  �3  �2  � ��� l  > >�1���1  � ) # otherwise include each test script   � ��� F   o t h e r w i s e   i n c l u d e   e a c h   t e s t   s c r i p t� ��� Z   > u���0�/� l  > A��.�-� =  > A��� o   > ?�,�,  0 statictestload staticTestLoad� m   ? @�+
�+ boovtrue�.  �-  � Y   D q��*���)� Z   Q l���(�'� l  Q W��&�%� >  Q W��� n   Q U��� 4   R U�$�
�$ 
cobj� o   S T�#�# 0 i  � o   Q R�"�" 0 scriptz  � m   U V�!
�! 
null�&  �%  � I  Z h� ��
�  .rdwrwritnull���     ****� b   Z b��� b   Z `��� m   Z [�� ��� L 	 	 < s c r i p t   t y p e = " t e x t / j a v a s c r i p t "   s r c = "� l  [ _���� n   [ _��� 4   \ _��
� 
cobj� o   ] ^�� 0 i  � o   [ \�� 0 scriptz  �  �  � m   ` a�� ���  " > < / s c r i p t > � � �
� 
refn  o   c d�� 	0 phile  �  �(  �'  �* 0 i  � m   G H�� � l  H L�� n   H L 1   I K�
� 
leng o   H I�� 0 scriptz  �  �  �)  �0  �/  �  l  v v����  �  �    l  v v�	�     kick it off!   	 �

    k i c k   i t   o f f ! � I  v �
� .rdwrwritnull���     **** m   v y � � 
 	 	 < s c r i p t > E S 5 H a r n e s s . s t a r t T e s t i n g ( ) ; < / s c r i p t > 
 	 < / b o d y > 
 < / h t m l > 
 ��
� 
refn o   z {�
�
 	0 phile  �  �  � �	 l     ����  �  �  �	       ��   ����� ��
� .aevtoappnull  �   � ****� 0 
find_tests  � 0 add_test  � 0 write_header  �  0 write_content  �� 0 write_footer   �� ������
�� .aevtoappnull  �   � ****�� 0 argv  ��   ������ 0 argv  �� 0 i   %�������� >�������������� b���������� � ��������� �������������������������
�� 
leng�� 0 foo  ��  ��  
�� .earsffdralis        afdr
�� 
cfol
�� 
rslt�� 0 myfolder myFolder
�� 
ctnr
�� 
utxt�� 0 
mainfolder 
mainFolder��  0 startingfolder startingFolder�� 0 toplevel topLevel��  0 statictestload staticTestLoad�� 0 scriptz  
�� 
cobj
�� .coredoexbool       obj �� 0 
find_tests  �� 0 add_test  
�� 
TEXT�� 0 target_file_path  
�� 
file
�� 
perm
�� .rdwropenshor       file�� 	0 phile  
�� 
set2
�� .rdwrseofnull���     ****�� 0 write_header  �� 0 write_content  �� 0 write_footer  
�� .rdwrclosnull���     ****
�� .aevtodocnull  �    alis��$ 
��,E�W X  jvE�O� 
)j �,EUO�E�O� ��,�&UO�E�O��%E�OfE�OeE�OjvE` O 8k��,Ekh �a �/a   eE�Y �a �/a   fE�Y h[OY��O� *��/j  )�k+ Y )�k+ UO V�a &a %E` O*a _ /a el E` O_ a jl O*_ k+  O*_ k+ !O*_ k+ "O_ j #W X   _ j #W X  hO� 	_ j $UOP ���������� 0 
find_tests  �� ����   ���� 	0 fpath  ��   �������������� 	0 fpath  �� 	0 itemz  �� 0 
subfolders  �� 0 	foundfile 	foundFile�� 0 i  �� 0 myitem myItem �������������P����a������
�� 
TEXT
�� 
lfiv
�� .earslfdrutxt  @    file
�� 
kocl
�� 
cobj
�� .corecnte****       ****
�� 
alis
�� 
kind�� 0 add_test  
�� 
null�� 0 
find_tests  �� �� ���&E�O��fl E�OjvE�OfE�O 7�[��l kh ��%�%�&E�O��,�  	��6FY )�k+ OeE�[OY��O� )�k+ Y hO �[��l kh )�k+ [OY��OPU ����������� 0 add_test  �� �� ��    ���� 0 script_path  ��   �������� 0 script_path  �� 0 base  �� 
0 prefix   �������������������������
�� 
null
�� 
psxp
�� 
TEXT
�� 
psof
�� 
psin�� 
�� .sysooffslong    ��� null
�� 
cha 
�� 
leng�� 0 toplevel topLevel�� 0 scriptz  �� W�� L��,�&E�O*���� E�O�E�O�j $�[�\[Z�\Z��,2�&E�O�f  �E�Y hY hO��%E�Y hO��6F ��#����!"���� 0 write_header  �� ��#�� #  ���� 	0 phile  ��  ! ������ 	0 phile  �� 
0 prefix  " 	+����4��?IKT
�� 
refn
�� .rdwrwritnull���     ****�� 0 toplevel topLevel�� 0��l O�E�O�e  �E�Y hO�%�%�l O��l OP ��d����$%���� 0 write_content  �� ��&�� &  ���� 	0 phile  ��  $ ������ 	0 phile  �� 0 i  % 	��������y������� 0 scriptz  
�� 
leng
�� 
cobj
�� 
null
�� 
refn
�� .rdwrwritnull���     ****�� 4 2k��,Ekh ��/� ���/%�%�l Y 	��l [OY�� �������'(���� 0 write_footer  �� ��)�� )  ���� 	0 phile  ��  ' �������� 	0 phile  �� 
0 prefix  �� 0 i  ( ������������������������
�� 
refn
�� .rdwrwritnull���     ****��  0 statictestload staticTestLoad�� 0 toplevel topLevel�� 0 scriptz  
�� 
leng
�� 
cobj
�� 
null�� ���l O�e (�E�O�e  �E�Y hO��l O��%�l Y hO��l O�e  2 ,k��,Ekh ��/� ���/%�%�l Y h[OY��Y hOa �l  ascr  ��ޭ