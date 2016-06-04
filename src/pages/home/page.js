import React from "react";
import styles from "./style.css";
import {Motion, spring, presets} from 'react-motion';

export default class HomePage extends React.Component {

  constructor() {
    super();
    this.state = {};
  }

  componentDidMount() {
    this.loadData();
  }
  
  render() {
    return (
      <div className={styles.content}>
        <h1>OFFHack</h1>
        { this.state.data == null && <p>Indlæser...</p> }
        { this.state.data != null && <MovieList data={this.state.data} onPosterClick={this.handlePosterClick} />}
        <MovieDetails movie={this.state.selectedMovie} onMovieDetailsClose={this.handleMovieDetailsClose} />
      </div>
    );
  }
  
  loadData = () => {
    fetch("http://10.10.5.123:8529/_db/_system/off2016/films").then(data => {
      return data.json();
    }).then(data => {
      this.setState({
        data: data
      });
    });
  }

  handleMovieDetailsClose = () => {
    this.setState({
      selectedMovie: null
    });
  }

  handlePosterClick = (movie) => {
    this.setState({
      selectedMovie: movie
    });
  }
}

class MovieDetails extends React.Component {

  render() {
    let movie = this.props.movie;

    if(movie) {
      return (
        <div className={styles.overlay}>
          <Motion defaultStyle={{x: -200, x2: 50, a: 0}} style={{x: spring(0), a: spring(1), x2: spring(0)}}>
            {value => (
              <div className={styles.movieDetails}>
                <div style={{ transform: `translate3d(${value.x}px, 0, 0)`, opacity: value.a}}>
                  <MoviePoster movie={this.props.movie} onPosterClick={()=>{}} />
                </div>
                <div>
                  <div 
                    className={styles.movieTitle}
                    style={{ transform: `translate3d(0, ${value.x}px, 0)` }}>
                    { movie.en_title }
                  </div>
                  <div>
                    <div style={{ transform: `translate3d(0, ${value.x}px, 0)`, opacity: value.a }}>{ movie.country }</div>
                  </div>
                  <div className={styles.description} style={{ transform: `translate3d(${value.x2}px, 0, 0)` }}>
                    { movie.en_description }
                  </div>
                  <div className={styles.castList} style={{ transform: `translate3d(0, ${-value.x}px, 0)`, opacity: value.a }}>
                    { movie.cast.map(c=> (
                      <div key={c.cast_id}>
                        <div className={styles.castImage}>
                        {c.image_path && <img src={"https://image.tmdb.org/t/p/w396" + c.image_path}/>}
                        {!c.image_path && <img src="https://www.canvs.in/static/img/profile_pic.png" /> }
                        <div style={{ "textAlign": "center" }}>{c.name}</div>
                        </div>
                      </div>
                      ))
                    }
                  </div>
                  <button onClick={this.props.onMovieDetailsClose}>Close</button>
                </div>
              </div>
            )}
    
          </Motion>
        </div>
      );      
    } else {
      return (<div>
      </div>)
    }

  }

}

class MovieList extends React.Component {

  render() {

    let onlyWithPictures = (m) => m.poster_path != null;
    let onlyEnriched = (m) => m.movie_db_id != -1;

    return (
      <div className={styles.movieList}>
        {this.props.data.filter(m=>m != null).filter(onlyEnriched).map(m=>{
          return <Movie {...this.props} key={m._key} movie={m} />
        })}
      </div>
    );
  }

}

class Movie extends React.Component {

  render() {

    let m = this.props.movie;

    return <div className={styles.movie}>
      <MoviePoster {...this.props} movie={m}/>
    </div>
  }

}

class MoviePoster extends React.Component {

  render() {
    let m = this.props.movie;
    if(m.poster_path) {
      return <div onClick={this.props.onPosterClick.bind(null, this.props.movie)} className={styles.imagePoster + " " + styles.poster}><img key={m._key} src={"https://image.tmdb.org/t/p/w396" + m.poster_path} /></div>
    } else {
      return <div onClick={this.props.onPosterClick.bind(null, this.props.movie)} className={styles.textPoster + " " + styles.poster}>{m.original_title}</div>
    }
  }

}
