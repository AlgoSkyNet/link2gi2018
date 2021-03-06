test -r ~/.alias && . ~/.alias
PS1='GRASS 7.4.1 (ecad17_ll):\w > '
grass_prompt() {
	LOCATION="`g.gisenv get=GISDBASE,LOCATION_NAME,MAPSET separator='/'`"
	if test -d "$LOCATION/grid3/G3D_MASK" && test -f "$LOCATION/cell/MASK" ; then
		echo [2D and 3D raster MASKs present]
	elif test -f "$LOCATION/cell/MASK" ; then
		echo [Raster MASK present]
	elif test -d "$LOCATION/grid3/G3D_MASK" ; then
		echo [3D raster MASK present]
	fi
}
PROMPT_COMMAND=grass_prompt
export PATH="/usr/lib/grass74/bin:/usr/lib/grass74/scripts:/home/creu/.grass7/addons/bin:/home/creu/.grass7/addons/scripts:/home/creu/anaconda3/bin:/usr/local/cdo:/usr/local/ncl-6.3.0/bin:/usr/local/cdo:/usr/local/cdo:/home/creu/bin:/home/creu/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games"
export HOME="/home/creu"
