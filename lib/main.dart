import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

const _accent = Color(0xFFB9F6CA);
const _bg = Color(0xFF090A0D);
const _surface = Color(0xFF111318);
const _muted = Color(0xFF9A9DA5);

void main() => runApp(const FlareTunesApp());

class FlareTunesApp extends StatelessWidget {
  const FlareTunesApp({super.key});
  @override Widget build(BuildContext context) => MaterialApp(
    title: 'FlareTunes', debugShowCheckedModeBanner: false,
    theme: ThemeData(brightness: Brightness.dark, scaffoldBackgroundColor: _bg,
      colorScheme: ColorScheme.fromSeed(seedColor: _accent, brightness: Brightness.dark),
      useMaterial3: true),
    home: const Shell(),
  );
}

class Track {
  final String title, artist, art;
  const Track(this.title, this.artist, this.art);
}
const tracks = [
  Track('Midnight City','M83','https://images.unsplash.com/photo-1519608487953-e999c86e7455?w=900'),
  Track('After Dark','Mr.Kitty','https://images.unsplash.com/photo-1516280440614-37939bbacd81?w=900'),
  Track('Blinding Lights','The Weeknd','https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=900'),
  Track('505','Arctic Monkeys','https://images.unsplash.com/photo-1501386761578-eac5c94b800a?w=900'),
  Track('Space Song','Beach House','https://images.unsplash.com/photo-1500534623283-312aade485b7?w=900'),
  Track('Sweater Weather','The Neighbourhood','https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=900'),
];

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override State<Shell> createState() => _ShellState();
}
class _ShellState extends State<Shell> {
  int tab = 0; Track? current; bool playing = false;
  final player = AudioPlayer();
  @override void dispose(){player.dispose();super.dispose();}
  Future<void> play(Track t) async {
    setState((){current=t;playing=true;});
  }
  void openPlayer(){
    if(current==null)return;
    Navigator.push(context,PageRouteBuilder(
      opaque:false,transitionDuration:const Duration(milliseconds:420),
      pageBuilder:(_,a,__)=>
        FullPlayer(track:current!,playing:playing,onToggle:()=>setState(()=>playing=!playing)),
      transitionsBuilder:(_,a,__,child)=>FadeTransition(
        opacity:CurvedAnimation(parent:a,curve:Curves.easeOutCubic),
        child:SlideTransition(position:Tween(begin:const Offset(0,.12),end:Offset.zero)
          .animate(CurvedAnimation(parent:a,curve:Curves.easeOutCubic)),child:child))));
  }
  @override Widget build(BuildContext context){
    final pages=[Home(onPlay:play),Search(onPlay:play),Library(onPlay:play),const Settings()];
    return Scaffold(body:Stack(children:[
      pages[tab],
      if(current!=null)Positioned(left:12,right:12,bottom:10,
        child:MiniPlayer(track:current!,playing:playing,onTap:openPlayer,
          onToggle:()=>setState(()=>playing=!playing))),
    ]),
    bottomNavigationBar:NavigationBar(height:74,backgroundColor:Colors.transparent,
      indicatorColor:_accent.withOpacity(.16),selectedIndex:tab,
      onDestinationSelected:(i)=>setState(()=>tab=i),destinations:const[
        NavigationDestination(icon:Icon(Icons.home_outlined),selectedIcon:Icon(Icons.home),label:'Home'),
        NavigationDestination(icon:Icon(Icons.search),label:'Search'),
        NavigationDestination(icon:Icon(Icons.library_music_outlined),selectedIcon:Icon(Icons.library_music),label:'Library'),
        NavigationDestination(icon:Icon(Icons.tune),label:'Settings'),
      ]));
  }
}

class Home extends StatelessWidget {
  final Future<void> Function(Track) onPlay;
  const Home({super.key,required this.onPlay});
  @override Widget build(BuildContext context)=>CustomScrollView(slivers:[
    const SliverAppBar.large(backgroundColor:_bg,title:Text('FlareTunes',
      style:TextStyle(fontWeight:FontWeight.w800,letterSpacing:-.8))),
    const SliverToBoxAdapter(child:_SectionTitle('Quick picks')),
    SliverToBoxAdapter(child:SizedBox(height:205,child:ListView.separated(
      padding:const EdgeInsets.symmetric(horizontal:18),scrollDirection:Axis.horizontal,
      itemCount:tracks.length,separatorBuilder:(_,__)=>const SizedBox(width:14),
      itemBuilder:(_,i)=>GestureDetector(onTap:()=>onPlay(tracks[i]),child:SizedBox(width:150,
        child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Hero(tag:'art-${tracks[i].title}',child:ClipRRect(borderRadius:BorderRadius.circular(18),
            child:CachedNetworkImage(imageUrl:tracks[i].art,height:150,width:150,fit:BoxFit.cover))),
          const SizedBox(height:9),Text(tracks[i].title,maxLines:1,overflow:TextOverflow.ellipsis,
            style:const TextStyle(fontWeight:FontWeight.w700)),
          Text(tracks[i].artist,maxLines:1,overflow:TextOverflow.ellipsis,
            style:const TextStyle(color:_muted,fontSize:12)),
        ])))))),
    const SliverToBoxAdapter(child:_SectionTitle('Recently played')),
    SliverList.builder(itemCount:tracks.length,itemBuilder:(_,i)=>TrackTile(
      track:tracks[i],onTap:()=>onPlay(tracks[i]))),
    const SliverPadding(padding:EdgeInsets.only(bottom:100)),
  ]);
}

class Search extends StatefulWidget {
  final Future<void> Function(Track) onPlay;
  const Search({super.key,required this.onPlay});
  @override State<Search> createState()=>_SearchState();
}
class _SearchState extends State<Search>{
  final controller=TextEditingController();String query='';
  @override Widget build(BuildContext context){
    final results=tracks.where((t)=>'${t.title} ${t.artist}'.toLowerCase().contains(query.toLowerCase())).toList();
    return SafeArea(child:CustomScrollView(slivers:[
      const SliverToBoxAdapter(child:Padding(padding:EdgeInsets.fromLTRB(20,24,20,8),
        child:Text('Search',style:TextStyle(fontSize:34,fontWeight:FontWeight.w800,letterSpacing:-1)))),
      SliverToBoxAdapter(child:Padding(padding:const EdgeInsets.all(16),child:TextField(
        controller:controller,onChanged:(v)=>setState(()=>query=v),
        decoration:InputDecoration(hintText:'Songs, artists, albums',prefixIcon:const Icon(Icons.search),
          filled:true,fillColor:_surface,border:OutlineInputBorder(
            borderRadius:BorderRadius.circular(20),borderSide:BorderSide.none))))),
      SliverList.builder(itemCount:results.length,itemBuilder:(_,i)=>TrackTile(
        track:results[i],onTap:()=>widget.onPlay(results[i]))),
      const SliverPadding(padding:EdgeInsets.only(bottom:100)),
    ]));
  }
}

class Library extends StatelessWidget{
  final Future<void> Function(Track) onPlay;
  const Library({super.key,required this.onPlay});
  @override Widget build(BuildContext context)=>CustomScrollView(slivers:[
    const SliverAppBar.large(backgroundColor:_bg,title:Text('Library',style:TextStyle(fontWeight:FontWeight.w800))),
    SliverToBoxAdapter(child:Padding(padding:const EdgeInsets.symmetric(horizontal:18),
      child:Row(children:[Expanded(child:_LibraryCard(icon:Icons.favorite_rounded,title:'Liked Songs',count:tracks.length.toString())),
        const SizedBox(width:12),const Expanded(child:_LibraryCard(icon:Icons.download_rounded,title:'Downloads',count:'0'))]))),
    const SliverToBoxAdapter(child:_SectionTitle('Your music')),
    SliverList.builder(itemCount:tracks.length,itemBuilder:(_,i)=>TrackTile(track:tracks[i],onTap:()=>onPlay(tracks[i]))),
    const SliverPadding(padding:EdgeInsets.only(bottom:100)),
  ]);
}

class Settings extends StatelessWidget{
  const Settings({super.key});
  @override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.fromLTRB(18,58,18,100),children:[
    const Text('Settings',style:TextStyle(fontSize:34,fontWeight:FontWeight.w800,letterSpacing:-1)),
    const SizedBox(height:24),
    const _SettingsGroup(title:'Playback',children:[
      ListTile(leading:Icon(Icons.high_quality_outlined),title:Text('Audio quality'),subtitle:Text('High')),
      ListTile(leading:Icon(Icons.speed),title:Text('Playback speed'),subtitle:Text('1.0×')),
      ListTile(leading:Icon(Icons.timer_outlined),title:Text('Sleep timer')),
    ]),
    const SizedBox(height:16),
    const _SettingsGroup(title:'Appearance',children:[
      ListTile(leading:Icon(Icons.palette_outlined),title:Text('Dynamic artwork theme')),
      ListTile(leading:Icon(Icons.blur_on),title:Text('Glass interface')),
      ListTile(leading:Icon(Icons.dark_mode_outlined),title:Text('Dark mode')),
    ]),
  ]);
}

class FullPlayer extends StatefulWidget{
  final Track track;final bool playing;final VoidCallback onToggle;
  const FullPlayer({super.key,required this.track,required this.playing,required this.onToggle});
  @override State<FullPlayer> createState()=>_FullPlayerState();
}
class _FullPlayerState extends State<FullPlayer>{
  double progress=.32;
  @override Widget build(BuildContext context)=>Scaffold(backgroundColor:Colors.black.withOpacity(.97),
    body:GestureDetector(onVerticalDragEnd:(d){if((d.primaryVelocity??0)>450)Navigator.pop(context);},
      child:SafeArea(child:Padding(padding:const EdgeInsets.fromLTRB(22,10,22,24),child:Column(children:[
        Container(width:42,height:5,decoration:BoxDecoration(color:Colors.white24,borderRadius:BorderRadius.circular(99))),
        const SizedBox(height:22),
        Row(children:[IconButton(onPressed:()=>Navigator.pop(context),icon:const Icon(Icons.keyboard_arrow_down_rounded,size:32)),
          const Expanded(child:Center(child:Text('NOW PLAYING',style:TextStyle(fontSize:12,letterSpacing:2,fontWeight:FontWeight.w700,color:_muted)))),
          IconButton(onPressed:(){},icon:const Icon(Icons.more_horiz))]),
        const Spacer(),
        Hero(tag:'art-${widget.track.title}',child:ClipRRect(borderRadius:BorderRadius.circular(28),
          child:CachedNetworkImage(imageUrl:widget.track.art,width:double.infinity,
            height:MediaQuery.sizeOf(context).width-44,fit:BoxFit.cover))),
        const SizedBox(height:28),
        Row(children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(widget.track.title,maxLines:1,overflow:TextOverflow.ellipsis,
            style:const TextStyle(fontSize:25,fontWeight:FontWeight.w800,letterSpacing:-.5)),
          const SizedBox(height:4),Text(widget.track.artist,style:const TextStyle(color:_muted,fontSize:16))])),
          IconButton(onPressed:(){},icon:const Icon(Icons.favorite_border_rounded))]),
        const SizedBox(height:18),
        SliderTheme(data:SliderTheme.of(context).copyWith(trackHeight:3,thumbShape:const RoundSliderThumbShape(enabledThumbRadius:5)),
          child:Slider(value:progress,onChanged:(v)=>setState(()=>progress=v))),
        const Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
          Text('1:42',style:TextStyle(color:_muted,fontSize:12)),Text('4:18',style:TextStyle(color:_muted,fontSize:12))]),
        const SizedBox(height:8),
        Row(mainAxisAlignment:MainAxisAlignment.spaceAround,children:[
          IconButton(onPressed:(){},icon:const Icon(Icons.shuffle_rounded)),
          IconButton(onPressed:(){},icon:const Icon(Icons.skip_previous_rounded,size:36)),
          GestureDetector(onTap:widget.onToggle,child:Container(width:70,height:70,
            decoration:const BoxDecoration(shape:BoxShape.circle,color:_accent),
            child:Icon(widget.playing?Icons.pause_rounded:Icons.play_arrow_rounded,color:Colors.black,size:36))),
          IconButton(onPressed:(){},icon:const Icon(Icons.skip_next_rounded,size:36)),
          IconButton(onPressed:(){},icon:const Icon(Icons.repeat_rounded)),
        ]),
      ])))));
}

class MiniPlayer extends StatelessWidget{
  final Track track;final bool playing;final VoidCallback onTap,onToggle;
  const MiniPlayer({super.key,required this.track,required this.playing,required this.onTap,required this.onToggle});
  @override Widget build(BuildContext context)=>ClipRRect(borderRadius:BorderRadius.circular(24),
    child:BackdropFilter(filter:ImageFilter.blur(sigmaX:18,sigmaY:18),child:Container(height:66,padding:const EdgeInsets.all(7),
      decoration:BoxDecoration(color:Colors.white.withOpacity(.08),border:Border.all(color:Colors.white.withOpacity(.1)),
        borderRadius:BorderRadius.circular(24)),child:Row(children:[
        GestureDetector(onTap:onTap,child:ClipRRect(borderRadius:BorderRadius.circular(17),
          child:CachedNetworkImage(imageUrl:track.art,width:52,height:52,fit:BoxFit.cover))),
        const SizedBox(width:12),Expanded(child:GestureDetector(onTap:onTap,child:Column(
          mainAxisAlignment:MainAxisAlignment.center,crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(track.title,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.w700)),
          Text(track.artist,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(color:_muted,fontSize:12)),
        ]))),
        IconButton(onPressed:onToggle,icon:Icon(playing?Icons.pause_rounded:Icons.play_arrow_rounded)),
        IconButton(onPressed:(){},icon:const Icon(Icons.skip_next_rounded)),
      ]))));
}

class TrackTile extends StatelessWidget{
  final Track track;final VoidCallback onTap;
  const TrackTile({super.key,required this.track,required this.onTap});
  @override Widget build(BuildContext context)=>ListTile(onTap:onTap,
    contentPadding:const EdgeInsets.symmetric(horizontal:18,vertical:4),
    leading:ClipRRect(borderRadius:BorderRadius.circular(13),child:CachedNetworkImage(imageUrl:track.art,width:58,height:58,fit:BoxFit.cover)),
    title:Text(track.title,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.w700)),
    subtitle:Text(track.artist,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(color:_muted)),
    trailing:IconButton(onPressed:(){},icon:const Icon(Icons.more_vert)));
}

class _SectionTitle extends StatelessWidget{
  final String text;const _SectionTitle(this.text);
  @override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.fromLTRB(18,24,18,14),
    child:Text(text,style:const TextStyle(fontSize:21,fontWeight:FontWeight.w800,letterSpacing:-.4)));
}
class _LibraryCard extends StatelessWidget{
  final IconData icon;final String title,count;
  const _LibraryCard({required this.icon,required this.title,required this.count});
  @override Widget build(BuildContext context)=>Container(height:130,padding:const EdgeInsets.all(16),
    decoration:BoxDecoration(color:_surface,borderRadius:BorderRadius.circular(22)),child:Column(
      crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(icon,color:_accent),const Spacer(),
      Text(title,style:const TextStyle(fontWeight:FontWeight.w800)),Text('$count songs',style:const TextStyle(color:_muted,fontSize:12))]));
}
class _SettingsGroup extends StatelessWidget{
  final String title;final List<Widget> children;
  const _SettingsGroup({required this.title,required this.children});
  @override Widget build(BuildContext context)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Padding(padding:const EdgeInsets.only(left:6,bottom:8),child:Text(title.toUpperCase(),
      style:const TextStyle(color:_muted,fontSize:12,fontWeight:FontWeight.w700,letterSpacing:1.2))),
    Container(decoration:BoxDecoration(color:_surface,borderRadius:BorderRadius.circular(22)),child:Column(children:children))]);
}
