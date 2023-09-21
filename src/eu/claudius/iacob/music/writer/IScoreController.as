package eu.claudius.iacob.music.writer {

/**
 * Interface to be implemented by all score controllers; a "score controller" is essentially a class adding an
 * interactive layer to a score produced by ScoreWriter, the way that its elements can be targeted by CRUD
 * operations (i.e., they can be changed, deleted, or new ones can be added on-the-fly), individually or in
 * group, based on a selection mechanism.
 */
public interface IScoreController {
}
}
